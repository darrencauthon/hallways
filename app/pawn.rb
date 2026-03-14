class Pawn
  attr_reader :col, :row

  def initialize(col, row, color)
    @col = col
    @row = row
    @color = color
  end

  def render(args, board_x, board_y, cell_size, cell_gap)
    cell_x = board_x + (@col * (cell_size + cell_gap))
    cell_y = board_y + (@row * (cell_size + cell_gap))
    pawn_size = 28
    pawn_x = cell_x + ((cell_size - pawn_size) / 2)
    pawn_y = cell_y + ((cell_size - pawn_size) / 2)

    args.outputs.solids << {
      x: pawn_x,
      y: pawn_y,
      w: pawn_size,
      h: pawn_size,
      r: @color[0],
      g: @color[1],
      b: @color[2]
    }

    args.outputs.borders << {
      x: pawn_x,
      y: pawn_y,
      w: pawn_size,
      h: pawn_size,
      r: 220,
      g: 70,
      b: 70
    }
  end
end
