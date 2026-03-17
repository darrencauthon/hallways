class Square
  attr_reader :col, :row, :color, :cell_width, :cell_height

  def initialize(col, row, color, cell_width:, cell_height:)
    @col = col
    @row = row
    @color = color
    @cell_width = cell_width
    @cell_height = cell_height
  end

  def render(args, board_x, board_y, cell_gap)
    x = board_x + (col * (cell_width + cell_gap))
    y = board_y + (row * (cell_height + cell_gap))

    args.outputs.solids << {
      x: x,
      y: y,
      w: cell_width,
      h: cell_height,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end
end
