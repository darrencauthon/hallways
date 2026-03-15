require "app/pawn.rb"
require "app/board.rb"
require "app/wall.rb"
require "app/player.rb"
require "app/board_renderer.rb"
require "app/wall_renderer.rb"
require "app/pawn_renderer.rb"

class Game
  WALLS_PER_LANE = 10
  WALL_COLOR = [210, 165, 95]
  WALL_WIDTH = 90
  WALL_HEIGHT = 10

  attr_reader :pawns, :board, :walls, :players, :winner, :cell_gap

  def initialize(cell_width:, cell_height:, cell_gap: 6)
    @cell_gap = cell_gap
    @board = Board.new(cell_width: cell_width, cell_height: cell_height)
    @players = [
      Player.new("Player 1", game: self, winning_row: board.size - 1),
      Player.new("Player 2", game: self, winning_row: 0)
    ]
    @pawns = [
      Pawn.new(4, 0, [245, 245, 245], player: @players[0], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 8, [50, 50, 50], player: @players[1], cell_width: cell_width, cell_height: cell_height)
    ]
    @walls = build_walls
    @turn_index = 0
  end

  def current_player
    players[@turn_index]
  end

  def next_turn!
    @turn_index = (@turn_index + 1) % players.length
  end

  def can_move_pawn_to?(pawn, col, row)
    return false unless winner.nil?
    return false if pawn.nil?
    return false unless pawn.player == current_player
    return false unless board.square_at(col, row)
    return false unless legal_moves_for(pawn).any? { |move| move[:col] == col && move[:row] == row }

    true
  end

  def move_pawn_to(pawn, col, row)
    return false unless can_move_pawn_to?(pawn, col, row)

    pawn.move_to(col, row)
    @winner = pawn.player if pawn.player.winning_row == row
    next_turn! if winner.nil?
    true
  end

  def can_place_wall_in_well?(wall, wall_well, preferred_side: :positive)
    return false if winner
    return false if wall.nil? || wall_well.nil?
    return false if wall.player != current_player
    return false if wall.placed?
    wall_span = board.wall_span_from(wall_well, preferred_side: preferred_side)
    return false if wall_span.nil?
    return false if wall_span.any?(&:occupied?)
    return false if crosses_existing_wall_span?(wall_span)

    pawns.all? do |pawn|
      board.path_exists?(
        start_col: pawn.col,
        start_row: pawn.row,
        goal_row: pawn.player.winning_row,
        extra_occupied_wall_wells: wall_span
      )
    end
  end

  def place_wall_in_well(wall, wall_well)
    place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)
  end

  def place_wall_in_well_with_side(wall, wall_well, preferred_side:)
    return false unless can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

    wall_span = board.wall_span_from(wall_well, preferred_side: preferred_side)
    wall.assign_to_wall_wells(wall_span)
    wall_span.each { |occupied_well| occupied_well.assign_wall(wall) }
    next_turn!
    true
  end

  def sync_render_state(dragged_wall:, dragged_pawn:, dragged_pawn_offset_x:, dragged_pawn_offset_y:)
    @dragged_wall = dragged_wall
    @dragged_pawn = dragged_pawn
    @dragged_pawn_offset_x = dragged_pawn_offset_x
    @dragged_pawn_offset_y = dragged_pawn_offset_y
  end

  def reserve_wall_rects(args, board_x, board_y)
    wall_count = Game::WALLS_PER_LANE
    spacing = 10
    wall_w = walls[0].width
    total_w = (wall_count * wall_w) + ((wall_count - 1) * spacing)
    start_x = ((args.grid.w - total_w) / 2).to_i
    top_y = board_y + board_pixel_size + 36
    bottom_y = board_y - 46

    rects = {}
    walls.each do |wall|
      next if wall.placed?

      rects[wall] = {
        x: start_x + (wall.slot * (wall_w + spacing)),
        y: wall.lane == :top ? top_y : bottom_y,
        w: wall.width,
        h: wall.height
      }
    end

    rects
  end

  def render(
    args,
    board_x:,
    board_y:,
    wall_drop_target:,
    pawn_drop_target:
  )
    configure_renderers

    board_renderer.render(args, self, board_x, board_y)
    wall_renderer.render_wall_drop_target(args, board_x, board_y, wall_drop_target)
    wall_renderer.render_placed_walls(args, self, board_x, board_y)
    wall_renderer.render_reserve_walls(
      args,
      self,
      board_x,
      board_y,
      dragged_wall: @dragged_wall,
      dragged_rect: dragged_wall_rect(args, board_x, board_y),
      hover_wall: hovered_reserve_wall(args, board_x, board_y)
    )
    pawn_renderer.render_drop_target(args, board_x, board_y, pawn_drop_target)
    render_player_names(args, board_x, board_y)
    pawn_renderer.render(
      args,
      self,
      board_x,
      board_y,
      dragged_pawn: @dragged_pawn,
      dragged_pawn_x: dragged_pawn_x(args),
      dragged_pawn_y: dragged_pawn_y(args)
    )
  end

  private

  def configure_renderers
    return if @renderer_config == { cell_gap: cell_gap, board_pixel_size: board_pixel_size }

    @renderer_config = { cell_gap: cell_gap, board_pixel_size: board_pixel_size }
    @board_renderer = BoardRenderer.new(
      cell_size: board.cell_width,
      cell_gap: cell_gap,
      board_pixel_size: board_pixel_size
    )
    @wall_renderer = WallRenderer.new(
      cell_size: board.cell_width,
      cell_gap: cell_gap,
      board_pixel_size: board_pixel_size
    )
    @pawn_renderer = PawnRenderer.new(
      cell_size: board.cell_width,
      cell_gap: cell_gap
    )
  end

  def board_renderer
    @board_renderer
  end

  def wall_renderer
    @wall_renderer
  end

  def pawn_renderer
    @pawn_renderer
  end

  def render_player_names(args, board_x, board_y)
    top_name = players[1].name
    bottom_name = players[0].name
    center_x = board_x + (board_pixel_size / 2)

    args.outputs.labels << {
      x: center_x,
      y: board_y + board_pixel_size + 78,
      text: top_name,
      alignment_enum: 1,
      size_enum: 2,
      r: 235,
      g: 235,
      b: 235
    }

    args.outputs.labels << {
      x: center_x,
      y: board_y - 80,
      text: bottom_name,
      alignment_enum: 1,
      size_enum: 2,
      r: 235,
      g: 235,
      b: 235
    }
  end

  def board_pixel_size
    (board.size * board.cell_width) + ((board.size - 1) * cell_gap)
  end

  def hovered_reserve_wall(args, board_x, board_y)
    reserve_wall_rects(args, board_x, board_y).find do |_wall, rect|
      mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
    end&.first
  end

  def dragged_wall_rect(args, board_x, board_y)
    return nil if @dragged_wall.nil?

    hovered_well = hovered_wall_well(args, board_x, board_y)
    if hovered_well&.orientation == :vertical
      width = @dragged_wall.height
      height = @dragged_wall.width
    else
      width = @dragged_wall.width
      height = @dragged_wall.height
    end

    {
      x: mouse_x(args) - (width / 2),
      y: mouse_y(args) - (height / 2),
      w: width,
      h: height
    }
  end

  def dragged_pawn_x(args)
    mouse_x(args) - (@dragged_pawn_offset_x || 0)
  end

  def dragged_pawn_y(args)
    mouse_y(args) - (@dragged_pawn_offset_y || 0)
  end

  def hovered_wall_well(args, board_x, board_y)
    board.wall_wells.find do |wall_well|
      rect = wall_well.rect(
        board_x,
        board_y,
        cell_width: board.cell_width,
        cell_height: board.cell_height,
        cell_gap: cell_gap
      )

      mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
    end
  end

  def mouse_inside_rect?(args, x:, y:, w:, h:)
    mouse = args.inputs.mouse
    return false unless mouse
    return false if mouse.x.nil? || mouse.y.nil?

    mouse.x >= x &&
      mouse.x <= x + w &&
      mouse.y >= y &&
      mouse.y <= y + h
  end

  def mouse_x(args)
    args.inputs.mouse.x || 0
  end

  def mouse_y(args)
    args.inputs.mouse.y || 0
  end

  def adjacent?(from_col, from_row, to_col, to_row)
    ((from_col - to_col).abs + (from_row - to_row).abs) == 1
  end

  def legal_moves_for(pawn)
    orthogonal_neighbors(pawn.col, pawn.row).flat_map do |neighbor|
      next [] if board.path_blocked?(from_col: pawn.col, from_row: pawn.row, to_col: neighbor[:col], to_row: neighbor[:row])

      occupant = pawn_at(neighbor[:col], neighbor[:row])
      if occupant.nil?
        [neighbor]
      else
        jump_moves_for(pawn, occupant)
      end
    end
  end

  def pawn_at?(col, row)
    pawns.any? { |pawn| pawn.col == col && pawn.row == row }
  end

  def pawn_at(col, row)
    pawns.find { |pawn| pawn.col == col && pawn.row == row }
  end

  def jump_moves_for(pawn, blocking_pawn)
    dx = blocking_pawn.col - pawn.col
    dy = blocking_pawn.row - pawn.row
    jump_col = blocking_pawn.col + dx
    jump_row = blocking_pawn.row + dy

    if board.square_at(jump_col, jump_row) &&
       !board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: jump_col, to_row: jump_row) &&
       !pawn_at?(jump_col, jump_row)
      [{ col: jump_col, row: jump_row }]
    else
      diagonal_jump_moves_for(blocking_pawn, dx: dx, dy: dy)
    end
  end

  def diagonal_jump_moves_for(blocking_pawn, dx:, dy:)
    if dx == 0
      [
        { col: blocking_pawn.col - 1, row: blocking_pawn.row },
        { col: blocking_pawn.col + 1, row: blocking_pawn.row }
      ]
    else
      [
        { col: blocking_pawn.col, row: blocking_pawn.row - 1 },
        { col: blocking_pawn.col, row: blocking_pawn.row + 1 }
      ]
    end.select do |move|
      board.square_at(move[:col], move[:row]) &&
        !board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: move[:col], to_row: move[:row]) &&
        !pawn_at?(move[:col], move[:row])
    end
  end

  def orthogonal_neighbors(col, row)
    [
      { col: col + 1, row: row },
      { col: col - 1, row: row },
      { col: col, row: row + 1 },
      { col: col, row: row - 1 }
    ].select { |move| board.square_at(move[:col], move[:row]) }
  end

  def crosses_existing_wall_span?(wall_span)
    walls.any? do |existing_wall|
      next false unless existing_wall.placed?

      spans_cross?(wall_span, existing_wall.wall_wells)
    end
  end

  def spans_cross?(first_span, second_span)
    first_orientation = first_span.first.orientation
    second_orientation = second_span.first.orientation
    return false if first_orientation == second_orientation

    first_anchor = span_anchor(first_span)
    second_anchor = span_anchor(second_span)

    first_anchor[:col] == second_anchor[:col] &&
      first_anchor[:row] == second_anchor[:row]
  end

  def span_anchor(span)
    {
      col: span.first.col,
      row: span.first.row
    }
  end

  def build_walls
    walls = []
    player_bottom = players[0]
    player_top = players[1]

    WALLS_PER_LANE.times do |slot|
      walls << Wall.new(lane: :top, slot: slot, width: WALL_WIDTH, height: WALL_HEIGHT, color: WALL_COLOR, player: player_top)
      walls << Wall.new(lane: :bottom, slot: slot, width: WALL_WIDTH, height: WALL_HEIGHT, color: WALL_COLOR, player: player_bottom)
    end

    walls
  end
end
