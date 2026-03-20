class Square
  attr_reader :col, :row, :color, :cell_width, :cell_height

  def initialize(col, row, color, cell_width:, cell_height:)
    @col = col
    @row = row
    @color = color
    @cell_width = cell_width
    @cell_height = cell_height
  end

  def render(args, board_x, board_y, cell_gap, color_override: nil)
    x = board_x + (col * (cell_width + cell_gap))
    y = board_y + (row * (cell_height + cell_gap))
    render_color = color_override || color

    args.outputs.solids << {
      x: x,
      y: y,
      w: cell_width,
      h: cell_height,
      r: render_color[0],
      g: render_color[1],
      b: render_color[2]
    }
  end
end
