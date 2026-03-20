require "app/renderers/board_renderer.rb"
require "app/renderers/wall_renderer.rb"
require "app/renderers/pawn_renderer.rb"

class GameRenderer
  DRAGGED_WALL_ROTATE_LERP = 0.28
  DRAGGED_WALL_ROTATE_EPSILON = 0.1
  PLAYER_NAME_SIZE_ENUM = 2
  PLAYER_NAME_COLOR = { r: 235, g: 235, b: 235 }.freeze
  PLAYER_BOX_W = 220
  PLAYER_BOX_H = 78
  PLAYER_BOX_GAP = 18
  PLAYER_BOX_RIGHT_MARGIN = 58
  PLAYER_BOX_LEFT_MARGIN = 58
  PLAYER_BOX_FILL = { r: 24, g: 26, b: 32, a: 220 }.freeze
  PLAYER_BOX_BORDER = { r: 88, g: 94, b: 110 }.freeze
  PLAYER_BOX_ACTIVE_BORDER = { r: 255, g: 215, b: 120 }.freeze
  PLAYER_BOX_META_COLOR = { r: 170, g: 176, b: 190 }.freeze

  attr_reader :cell_gap

  def initialize(cell_gap:)
    @cell_gap = cell_gap
  end

  def render(
    args,
    game:,
    board_x:,
    board_y:,
    wall_drop_target:,
    pawn_drop_target:,
    dragged_wall:,
    dragged_rect:,
    dragged_angle:,
    hover_wall:,
    dragged_pawn:,
    dragged_pawn_x:,
    dragged_pawn_y:
  )
    configure_renderers(game)

    board_renderer.render(args, game, board_x, board_y)
    wall_renderer.render_wall_drop_target(args, board_x, board_y, wall_drop_target)
    wall_renderer.render_placed_walls(args, game, board_x, board_y)
    wall_renderer.render_reserve_walls(
      args,
      game,
      board_x,
      board_y,
      {
        dragged_wall: dragged_wall,
        dragged_rect: dragged_rect,
        dragged_angle: dragged_angle,
        hover_wall: hover_wall
      }
    )
    pawn_renderer.render_drop_target(args, board_x, board_y, pawn_drop_target)
    render_player_boxes(args, game, board_x, board_y)
    pawn_renderer.render(
      args,
      game,
      board_x,
      board_y,
      dragged_pawn: dragged_pawn,
      dragged_pawn_x: dragged_pawn_x,
      dragged_pawn_y: dragged_pawn_y
    )
  end

  def reserve_wall_rects(args, game:, board_x:, board_y:)
    return reserve_wall_rects_for_four_players(args, game: game, board_x: board_x, board_y: board_y) if game.player_count == 4

    wall_count = Game::WALLS_PER_LANE
    spacing = 10
    wall_w = game.walls[0].width
    total_w = (wall_count * wall_w) + ((wall_count - 1) * spacing)
    start_x = ((args.grid.w - total_w) / 2).to_i
    top_y = board_y + board_pixel_size(game) + 36
    bottom_y = board_y - 46

    rects = {}
    game.walls.each do |wall|
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

  def hovered_reserve_wall(args, game:, board_x:, board_y:)
    reserve_wall_rects(args, game: game, board_x: board_x, board_y: board_y).find do |_wall, rect|
      mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
    end&.first
  end

  def dragged_wall_rect(args, game:, board_x:, board_y:, dragged_wall:, dragged_wall_orientation:)
    if dragged_wall.nil?
      reset_dragged_wall_preview_state
      return { rect: nil, orientation: nil, angle: nil }
    end

    hovered_well = hovered_wall_well(args, game: game, board_x: board_x, board_y: board_y)
    orientation = dragged_wall_orientation
    orientation = hovered_well.orientation if hovered_well

    target_angle = orientation == :vertical ? 90.0 : 0.0

    initialize_dragged_wall_preview_state_if_needed(dragged_wall)
    @dragged_wall_preview_angle = animate_angle(@dragged_wall_preview_angle, target_angle)

    {
      rect: {
        x: mouse_x(args) - (dragged_wall.width / 2),
        y: mouse_y(args) - (dragged_wall.height / 2),
        w: dragged_wall.width,
        h: dragged_wall.height
      },
      orientation: orientation,
      angle: @dragged_wall_preview_angle
    }
  end

  private

  def configure_renderers(game)
    config = {
      cell_gap: cell_gap,
      board_pixel_size: board_pixel_size(game),
      cell_size: game.board.cell_width
    }
    return if @renderer_config == config

    @renderer_config = config
    @board_renderer = BoardRenderer.new(
      cell_size: game.board.cell_width,
      cell_gap: cell_gap,
      board_pixel_size: board_pixel_size(game)
    )
    @wall_renderer = WallRenderer.new(
      cell_size: game.board.cell_width,
      cell_gap: cell_gap,
      board_pixel_size: board_pixel_size(game)
    )
    @pawn_renderer = PawnRenderer.new(
      cell_size: game.board.cell_width,
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

  def render_player_boxes(args, game, board_x, board_y)
    player_box_layouts(args, game, board_x, board_y).each do |entry|
      render_player_box(
        args,
        game,
        player: entry[:player],
        x: entry[:x],
        y: entry[:y],
        current: game.current_player == entry[:player]
      )
    end
  end

  def with_turn_indicator(player)
    indicator = player.turn_indicator_text
    return player.name if indicator.nil? || indicator.empty?

    "#{player.name} (#{indicator})"
  end

  def render_player_box(args, game, player:, x:, y:, current:)
    border_color = current ? PLAYER_BOX_ACTIVE_BORDER : PLAYER_BOX_BORDER

    args.outputs.solids << {
      x: x,
      y: y,
      w: PLAYER_BOX_W,
      h: PLAYER_BOX_H,
      **PLAYER_BOX_FILL
    }

    args.outputs.borders << {
      x: x,
      y: y,
      w: PLAYER_BOX_W,
      h: PLAYER_BOX_H,
      **border_color
    }

    args.outputs.labels << {
      x: x + 14,
      y: y + PLAYER_BOX_H - 18,
      text: player.name,
      size_enum: PLAYER_NAME_SIZE_ENUM,
      **PLAYER_NAME_COLOR
    }

    indicator = player.turn_indicator_text
    return if indicator.nil? || indicator.empty?

    args.outputs.labels << {
      x: x + 14,
      y: y + 32,
      text: indicator,
      size_enum: 1,
      **PLAYER_BOX_ACTIVE_BORDER
    }
  end

  def board_pixel_size(game)
    board = game.board
    (board.size * board.cell_width) + ((board.size - 1) * cell_gap)
  end

  def reserve_wall_rects_for_four_players(args, game:, board_x:, board_y:)
    rects = {}
    spacing = 10
    walls_per_player = game.walls.count { |wall| wall.player == game.players[0] }
    wall = game.walls[0]
    horizontal_w = wall.width
    horizontal_h = wall.height
    vertical_w = wall.height
    vertical_h = wall.width
    board_size = board_pixel_size(game)

    top_y = board_y + board_size + 36
    bottom_y = board_y - 46
    horizontal_total_w = (walls_per_player * horizontal_w) + ((walls_per_player - 1) * spacing)
    horizontal_start_x = ((args.grid.w - horizontal_total_w) / 2).to_i

    vertical_total_h = (walls_per_player * vertical_h) + ((walls_per_player - 1) * spacing)
    vertical_start_y = board_y + ((board_size - vertical_total_h) / 2).to_i
    left_x = board_x - 44
    right_x = board_x + board_size + 34

    game.walls.each do |candidate|
      next if candidate.placed?

      player_index = game.players.index(candidate.player) || 0
      slot_index = candidate.slot % walls_per_player

      if player_index == 0
        rects[candidate] = {
          x: horizontal_start_x + (slot_index * (horizontal_w + spacing)),
          y: bottom_y,
          w: horizontal_w,
          h: horizontal_h
        }
      elsif player_index == 1
        rects[candidate] = {
          x: horizontal_start_x + (slot_index * (horizontal_w + spacing)),
          y: top_y,
          w: horizontal_w,
          h: horizontal_h
        }
      elsif player_index == 2
        rects[candidate] = {
          x: left_x,
          y: vertical_start_y + (slot_index * (vertical_h + spacing)),
          w: vertical_w,
          h: vertical_h
        }
      else
        rects[candidate] = {
          x: right_x,
          y: vertical_start_y + (slot_index * (vertical_h + spacing)),
          w: vertical_w,
          h: vertical_h
        }
      end
    end

    rects
  end

  def player_box_layouts(args, game, board_x, board_y)
    board_size = board_pixel_size(game)
    right_x = board_x + board_size + PLAYER_BOX_RIGHT_MARGIN
    left_x = board_x - PLAYER_BOX_LEFT_MARGIN - PLAYER_BOX_W
    top_y = board_y + board_size - PLAYER_BOX_H
    bottom_y = board_y

    layouts = [
      { player: game.players[0], x: left_x, y: top_y },
      { player: game.players[1], x: right_x, y: bottom_y }
    ]
    return layouts if game.player_count < 4

    layouts << { player: game.players[2], x: left_x, y: bottom_y }
    layouts << { player: game.players[3], x: right_x, y: top_y }
    layouts
  end

  def remaining_walls_for(game, player)
    game.walls.count { |wall| wall.player == player && !wall.placed? }
  end

  def hovered_wall_well(args, game:, board_x:, board_y:)
    game.board.wall_wells.find do |wall_well|
      rect = wall_well.rect(
        board_x,
        board_y,
        cell_width: game.board.cell_width,
        cell_height: game.board.cell_height,
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

  def initialize_dragged_wall_preview_state_if_needed(dragged_wall)
    return if @dragged_wall_preview_wall == dragged_wall && !@dragged_wall_preview_angle.nil?

    @dragged_wall_preview_wall = dragged_wall
    @dragged_wall_preview_angle = 0.0
  end

  def animate_angle(current, target)
    return target if current.nil?

    delta = target - current
    return target if delta.abs <= DRAGGED_WALL_ROTATE_EPSILON

    current + (delta * DRAGGED_WALL_ROTATE_LERP)
  end

  def reset_dragged_wall_preview_state
    @dragged_wall_preview_wall = nil
    @dragged_wall_preview_angle = nil
  end
end
