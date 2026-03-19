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
    # Wall wells are invisible; highlights are rendered by wall-drop target UI.
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
