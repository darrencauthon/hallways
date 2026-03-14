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

  def square_at(col, row)
    return nil unless inside_bounds?(col, row)

    squares.find { |square| square.col == col && square.row == row }
  end

  def path_blocked?(from_col:, from_row:, to_col:, to_row:)
    wall_well_between(from_col: from_col, from_row: from_row, to_col: to_col, to_row: to_row)&.occupied? || false
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

  def inside_bounds?(col, row)
    col >= 0 && col < size && row >= 0 && row < size
  end

  def wall_well_between(from_col:, from_row:, to_col:, to_row:)
    if from_col == to_col
      lower_row = [from_row, to_row].min
      wall_wells.find do |wall_well|
        wall_well.orientation == :horizontal &&
          wall_well.col == from_col &&
          wall_well.row == lower_row
      end
    elsif from_row == to_row
      lower_col = [from_col, to_col].min
      wall_wells.find do |wall_well|
        wall_well.orientation == :vertical &&
          wall_well.col == lower_col &&
          wall_well.row == from_row
      end
    end
  end
end
