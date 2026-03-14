require "app/square.rb"

class Wall
  attr_reader :squares, :size, :cell_width, :cell_height

  def initialize(size: 9, cell_width:, cell_height:)
    @size = size
    @cell_width = cell_width
    @cell_height = cell_height
    @squares = build_squares
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
end
