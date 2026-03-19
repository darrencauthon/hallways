require "app/renderers/board_renderer.rb"
require "app/renderers/wall_renderer.rb"
require "app/renderers/pawn_renderer.rb"

class GameRenderer
  DRAGGED_WALL_ROTATE_LERP = 0.28
  DRAGGED_WALL_ROTATE_EPSILON = 0.1

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
    render_player_names(args, game, board_x, board_y)
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

  def render_player_names(args, game, board_x, board_y)
    top_player = game.players[1]
    bottom_player = game.players[0]
    top_name = with_turn_indicator(top_player)
    bottom_name = with_turn_indicator(bottom_player)
    center_x = board_x + (board_pixel_size(game) / 2)

    args.outputs.labels << {
      x: center_x,
      y: board_y + board_pixel_size(game) + 78,
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

  def with_turn_indicator(player)
    indicator = player.turn_indicator_text
    return player.name if indicator.nil? || indicator.empty?

    "#{player.name} (#{indicator})"
  end

  def board_pixel_size(game)
    board = game.board
    (board.size * board.cell_width) + ((board.size - 1) * cell_gap)
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
