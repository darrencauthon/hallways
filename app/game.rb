require "app/pawn.rb"
require "app/board.rb"

class Game
  attr_reader :pawns, :board

  def initialize(cell_width:, cell_height:)
    @board = Board.new(cell_width: cell_width, cell_height: cell_height)
    @pawns = [
      Pawn.new(4, 8, [245, 245, 245], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 0, [50, 50, 50], cell_width: cell_width, cell_height: cell_height)
    ]
  end
end
