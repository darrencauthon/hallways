class PawnRenderer
  def initialize(cell_size:, cell_gap:)
    @cell_size = cell_size
    @cell_gap = cell_gap
  end

  def render(args, game, board_x, board_y, dragged_pawn:, dragged_pawn_x:, dragged_pawn_y:)
    game.pawns.each do |pawn|
      if pawn == dragged_pawn
        pawn.render_at(args, dragged_pawn_x, dragged_pawn_y)
      else
        pawn.render(args, board_x, board_y, @cell_gap)
      end
    end
  end

  def render_drop_target(args, board_x, board_y, square)
    return if square.nil?

    x = board_x + (square.col * (@cell_size + @cell_gap))
    y = board_y + (square.row * (@cell_size + @cell_gap))

    args.outputs.borders << {
      x: x - 2,
      y: y - 2,
      w: @cell_size + 4,
      h: @cell_size + 4,
      r: 240,
      g: 60,
      b: 60
    }
  end
end
