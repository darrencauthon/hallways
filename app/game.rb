require "app/pawn.rb"
require "app/square.rb"

class Game
  attr_reader :pawns, :squares

  def initialize(cell_width:, cell_height:)
    @squares = build_squares(cell_width, cell_height)
    @pawns = [
      Pawn.new(4, 8, [245, 245, 245], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 0, [50, 50, 50], cell_width: cell_width, cell_height: cell_height)
    ]
  end

  private

  def build_squares(cell_width, cell_height)
    squares = []
    color = [225, 214, 189]

    9.times do |row|
      9.times do |col|
        squares << Square.new(col, row, color, cell_width: cell_width, cell_height: cell_height)
      end
    end

    squares
  end
end
