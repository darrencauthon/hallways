class Pawn
  attr_reader :col, :row, :color, :cell_width, :cell_height, :player

  def initialize(col, row, color, player:, cell_width:, cell_height:)
    @col = col
    @row = row
    @color = color
    @player = player
    @cell_width = cell_width
    @cell_height = cell_height
  end

  def render(args, board_x, board_y, cell_gap)
    cell_x = board_x + (col * (cell_width + cell_gap))
    cell_y = board_y + (row * (cell_height + cell_gap))
    pawn_size = 28
    pawn_x = cell_x + ((cell_width - pawn_size) / 2)
    pawn_y = cell_y + ((cell_height - pawn_size) / 2)

    args.outputs.solids << {
      x: pawn_x,
      y: pawn_y,
      w: pawn_size,
      h: pawn_size,
      r: color[0],
      g: color[1],
      b: color[2]
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

  def move_to(col, row)
    @col = col
    @row = row
  end
end
