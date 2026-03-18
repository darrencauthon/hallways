class GameRenderer
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
      dragged_wall: dragged_wall,
      dragged_rect: dragged_rect,
      hover_wall: hover_wall
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
    top_name = game.players[1].name
    bottom_name = game.players[0].name
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

  def board_pixel_size(game)
    board = game.board
    (board.size * board.cell_width) + ((board.size - 1) * cell_gap)
  end
end
