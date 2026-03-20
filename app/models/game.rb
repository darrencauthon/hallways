require "app/models/pawn.rb"
require "app/models/board.rb"
require "app/models/wall.rb"
require "app/models/player.rb"
require "app/controllers/null_controller.rb"
require "app/controllers/bot_controller.rb"
require "app/controllers/human_controller.rb"
require "app/controllers/random_bot_controller.rb"
require "app/controllers/path_bot_controller.rb"
require "app/controllers/last_line_bot_controller.rb"
require "app/controllers/pressure_bot_controller.rb"
require "app/renderers/game_renderer.rb"

class Game
  WALLS_PER_LANE = 10
  WALLS_PER_PLAYER_TWO = 10
  WALLS_PER_PLAYER_FOUR = 5
  WALL_COLOR = [210, 165, 95]
  WALL_WIDTH = 90
  WALL_HEIGHT = 10
  PLAYER_COLORS = [
    [143, 45, 45],
    [47, 75, 143],
    [47, 107, 69],
    [154, 106, 31]
  ].freeze

  attr_reader :pawns, :board, :walls, :players, :winner, :cell_gap, :mode, :player_types, :player_count

  def initialize(cell_width:, cell_height:, cell_gap: 6, mode: :human_vs_human, player_types: nil, player_count: nil)
    @mode = mode
    @player_count = player_count || (player_types&.length || 2)
    @player_types = player_types || default_player_types_for_count(@player_count)
    @player_count = @player_types.length
    @cell_gap = cell_gap
    @board = Board.new(cell_width: cell_width, cell_height: cell_height)
    @players = build_players
    @pawns = build_pawns(cell_width: cell_width, cell_height: cell_height)
    @walls = build_walls
    @turn_index = 0
  end

  def current_player
    players[@turn_index]
  end

  def current_controller
    current_player.controller
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
    @winner = pawn.player if pawn.player.goal_reached?(col, row)
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
        goal_col: pawn.player.winning_col,
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
    @dragged_wall_orientation = nil if dragged_wall.nil?
  end

  def reserve_wall_rects(args, board_x, board_y)
    game_renderer.reserve_wall_rects(args, game: self, board_x: board_x, board_y: board_y)
  end

  def render(
    args,
    board_x:,
    board_y:,
    wall_drop_target:,
    pawn_drop_target:
  )
    renderer = game_renderer
    dragged_wall_preview = renderer.dragged_wall_rect(
      args,
      game: self,
      board_x: board_x,
      board_y: board_y,
      dragged_wall: @dragged_wall,
      dragged_wall_orientation: @dragged_wall_orientation
    )
    @dragged_wall_orientation = dragged_wall_preview[:orientation]

    renderer.render(
      args,
      game: self,
      board_x: board_x,
      board_y: board_y,
      wall_drop_target: wall_drop_target,
      pawn_drop_target: pawn_drop_target,
      dragged_wall: @dragged_wall,
      dragged_rect: dragged_wall_preview[:rect],
      dragged_angle: dragged_wall_preview[:angle],
      hover_wall: renderer.hovered_reserve_wall(args, game: self, board_x: board_x, board_y: board_y),
      dragged_pawn: @dragged_pawn,
      dragged_pawn_x: dragged_pawn_x(args),
      dragged_pawn_y: dragged_pawn_y(args)
    )
  end

  private

  def default_player_types_for_count(player_count)
    return [:human, :human, :human, :human] if player_count == 4

    player_types_for_mode(mode)
  end

  def player_types_for_mode(mode)
    return [:human, :random_bot] if mode == :human_vs_computer

    [:human, :human]
  end

  def build_player(index:, winning_row:, winning_col: nil)
    player_type = player_types[index]
    Player.new(
      display_name_for(index, player_type),
      game: self,
      winning_row: winning_row,
      winning_col: winning_col,
      controller: controller_for(player_type)
    )
  end

  def display_name_for(index, player_type)
    prefix = bot_player_type?(player_type) ? "Bot" : "Player"
    "#{prefix} #{index + 1}"
  end

  def controller_for(player_type)
    return PathBotController.new if player_type == :path_bot
    return LastLineBotController.new if player_type == :last_line_bot
    return PressureBotController.new if player_type == :pressure_bot
    return RandomBotController.new if bot_player_type?(player_type)

    HumanController.new
  end

  def bot_player_type?(player_type)
    player_type == :random_bot || player_type == :computer || player_type == :path_bot || player_type == :last_line_bot || player_type == :pressure_bot
  end

  def game_renderer
    if @game_renderer.nil? || @game_renderer.cell_gap != cell_gap
      @game_renderer = GameRenderer.new(cell_gap: cell_gap)
    end

    @game_renderer
  end

  def dragged_pawn_x(args)
    mouse_x(args) - (@dragged_pawn_offset_x || 0)
  end

  def dragged_pawn_y(args)
    mouse_y(args) - (@dragged_pawn_offset_y || 0)
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
    orthogonal_neighbors(pawn).flat_map do |neighbor|
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

  def orthogonal_neighbors(pawn)
    [
      { col: pawn.col + 1, row: pawn.row },
      { col: pawn.col - 1, row: pawn.row },
      { col: pawn.col, row: pawn.row + 1 },
      { col: pawn.col, row: pawn.row - 1 }
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
    walls_per_player = player_count == 4 ? WALLS_PER_PLAYER_FOUR : WALLS_PER_PLAYER_TWO

    players.each_with_index do |player, index|
      lane = wall_lane_for_player(index)
      slot_offset = wall_slot_offset_for_player(index)
      walls_per_player.times do |slot|
        walls << Wall.new(
          lane: lane,
          slot: slot_offset + slot,
          width: WALL_WIDTH,
          height: WALL_HEIGHT,
          color: WALL_COLOR,
          player: player
        )
      end
    end

    walls
  end

  def wall_lane_for_player(index)
    return :bottom if index == 0 || index == 2

    :top
  end

  def wall_slot_offset_for_player(index)
    return 0 unless player_count == 4
    return 5 if index == 2 || index == 3

    0
  end

  def build_players
    configs = player_start_configs
    configs.each_with_index.map do |config, index|
      build_player(index: index, winning_row: config[:winning_row], winning_col: config[:winning_col])
    end
  end

  def build_pawns(cell_width:, cell_height:)
    configs = player_start_configs
    configs.each_with_index.map do |config, index|
      color = pawn_color_for(index)
      Pawn.new(
        config[:start_col],
        config[:start_row],
        color,
        player: @players[index],
        cell_width: cell_width,
        cell_height: cell_height
      )
    end
  end

  def pawn_color_for(index)
    PLAYER_COLORS[index] || PLAYER_COLORS[0]
  end

  def player_start_configs
    if player_count == 4
      [
        { start_col: 4, start_row: 0, winning_row: 8, winning_col: nil },
        { start_col: 4, start_row: 8, winning_row: 0, winning_col: nil },
        { start_col: 0, start_row: 4, winning_row: nil, winning_col: 8 },
        { start_col: 8, start_row: 4, winning_row: nil, winning_col: 0 }
      ]
    else
      [
        { start_col: 4, start_row: 0, winning_row: 8, winning_col: nil },
        { start_col: 4, start_row: 8, winning_row: 0, winning_col: nil }
      ]
    end
  end
end
