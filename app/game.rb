require "app/pawn.rb"
require "app/wall.rb"

class Game
  attr_reader :pawns, :wall

  def initialize(cell_width:, cell_height:)
    @wall = Wall.new(cell_width: cell_width, cell_height: cell_height)
    @pawns = [
      Pawn.new(4, 8, [245, 245, 245], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 0, [50, 50, 50], cell_width: cell_width, cell_height: cell_height)
    ]
  end
end
