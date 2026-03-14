require "app/square.rb"
require "app/wall_well.rb"

class Board
  attr_reader :squares, :wall_wells, :size, :cell_width, :cell_height

  def initialize(size: 9, cell_width:, cell_height:)
    @size = size
    @cell_width = cell_width
    @cell_height = cell_height
    @squares = build_squares
    @wall_wells = build_wall_wells
  end

  private

  def build_squares
    squares = []
    color = [225, 214, 189]

    size.times do |row|
      size.times do |col|
        squares << Square.new(col, row, color, cell_width: cell_width, cell_height: cell_height)
      end
    end

    squares
  end

  def build_wall_wells
    wells = []

    (size - 1).times do |row|
      size.times do |col|
        wells << WallWell.new(
          col: col,
          row: row,
          width: 36,
          height: 10,
          orientation: :horizontal
        )
      end
    end

    size.times do |row|
      (size - 1).times do |col|
        wells << WallWell.new(
          col: col,
          row: row,
          width: 10,
          height: 36,
          orientation: :vertical
        )
      end
    end

    wells
  end
end
