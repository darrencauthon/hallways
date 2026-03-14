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
      Player.new("Player 1", game: self),
      Player.new("Player 2", game: self)
    ]
    @pawns = [
      Pawn.new(4, 0, [245, 245, 245], player: @players[0], cell_width: cell_width, cell_height: cell_height),
      Pawn.new(4, 8, [50, 50, 50], player: @players[1], cell_width: cell_width, cell_height: cell_height)
    ]
    @walls = build_walls
    @turn_index = 0
  end

  def current_player
    players[@turn_index]
  end

  def next_turn!
    @turn_index = (@turn_index + 1) % players.length
  end

  def move_pawn_to(pawn, col, row)
    return false if pawn.nil?
    return false unless pawn.player == current_player
    return false unless board.square_at(col, row)
    return false unless adjacent?(pawn.col, pawn.row, col, row)
    return false if board.path_blocked?(from_col: pawn.col, from_row: pawn.row, to_col: col, to_row: row)
    return false if pawn_at?(col, row)

    pawn.move_to(col, row)
    next_turn!
    true
  end

  def place_wall_in_well(wall, wall_well)
    return if wall.nil? || wall_well.nil?
    return if wall.placed?
    return if wall_well.occupied?

    wall.assign_to_wall_well(wall_well)
    wall_well.assign_wall(wall)
    next_turn!
  end

  private

  def adjacent?(from_col, from_row, to_col, to_row)
    ((from_col - to_col).abs + (from_row - to_row).abs) == 1
  end

  def pawn_at?(col, row)
    pawns.any? { |pawn| pawn.col == col && pawn.row == row }
  end

  def build_walls
    walls = []
    player_bottom = players[0]
    player_top = players[1]

    WALLS_PER_LANE.times do |slot|
      walls << Wall.new(lane: :top, slot: slot, width: 36, height: 10, color: WALL_COLOR, player: player_top)
      walls << Wall.new(lane: :bottom, slot: slot, width: 36, height: 10, color: WALL_COLOR, player: player_bottom)
    end

    walls
  end
end
