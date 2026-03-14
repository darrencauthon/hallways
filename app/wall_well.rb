class WallWell
  attr_reader :col, :row, :width, :height, :orientation, :wall

  def initialize(col:, row:, width:, height:, orientation:)
    @col = col
    @row = row
    @width = width
    @height = height
    @orientation = orientation
  end

  def occupied?
    !wall.nil?
  end

  def assign_wall(wall)
    @wall = wall
  end

  def render(args, board_x, board_y, cell_width:, cell_height:, cell_gap:)
    rect = rect(board_x, board_y, cell_width: cell_width, cell_height: cell_height, cell_gap: cell_gap)
    color = occupied? ? [255, 40, 40] : [90, 30, 30]

    args.outputs.solids << {
      x: rect[:x],
      y: rect[:y],
      w: rect[:w],
      h: rect[:h],
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  def rect(board_x, board_y, cell_width:, cell_height:, cell_gap:)
    if horizontal?
      x = board_x + (col * (cell_width + cell_gap)) + ((cell_width - width) / 2)
      y = board_y + (row * (cell_height + cell_gap)) + cell_height + ((cell_gap - height) / 2)
    else
      x = board_x + (col * (cell_width + cell_gap)) + cell_width + ((cell_gap - width) / 2)
      y = board_y + (row * (cell_height + cell_gap)) + ((cell_height - height) / 2)
    end

    { x: x, y: y, w: width, h: height }
  end

  private

  def horizontal?
    orientation == :horizontal
  end
end
