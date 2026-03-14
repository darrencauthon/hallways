require "app/pawn.rb"
require "app/board.rb"
require "app/wall.rb"
require "app/player.rb"

class Game
  WALLS_PER_LANE = 10
  WALL_COLOR = [210, 165, 95]

  attr_reader :pawns, :board, :walls, :players

  def initialize(cell_width:, cell_height:)
    @board = Board.new(cell_width: cell_width, cell_height: cell_height)
    @players = [
      Player.new("Player 1"),
      Player.new("Player 2")
    ]
    @walls = build_walls
    @pawns = [
      Pawn.new(4, 8, [245, 245, 245], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 0, [50, 50, 50], cell_width: cell_width, cell_height: cell_height)
    ]
  end

  private

  def build_walls
    walls = []

    WALLS_PER_LANE.times do |slot|
      walls << Wall.new(lane: :top, slot: slot, width: 36, height: 10, color: WALL_COLOR)
      walls << Wall.new(lane: :bottom, slot: slot, width: 36, height: 10, color: WALL_COLOR)
    end

    walls
  end
end
