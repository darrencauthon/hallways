require "app/pawn.rb"
require "app/board.rb"
require "app/wall.rb"
require "app/player.rb"

class Game
  WALLS_PER_LANE = 10
  WALL_COLOR = [210, 165, 95]
  WALL_WIDTH = 90
  WALL_HEIGHT = 10

  attr_reader :pawns, :board, :walls, :players, :winner

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

  def can_move_pawn_to?(pawn, col, row)
    return false unless winner.nil?
    return false if pawn.nil?
    return false unless pawn.player == current_player
    return false unless board.square_at(col, row)
    return false unless legal_moves_for(pawn).any? { |move| move[:col] == col && move[:row] == row }

    true
  end

  def move_pawn_to(pawn, col, row)
    return false unless can_move_pawn_to?(pawn, col, row)

    pawn.move_to(col, row)
    @winner = pawn.player if winning_row_for?(pawn.player) == row
    next_turn! if winner.nil?
    true
  end

  def can_place_wall_in_well?(wall, wall_well, preferred_side: :positive)
    return false if winner
    return false if wall.nil? || wall_well.nil?
    return false if wall.player != current_player
    return false if wall.placed?
    wall_span = board.wall_span_from(wall_well, preferred_side: preferred_side)
    return false if wall_span.nil?
    return false if wall_span.any?(&:occupied?)
    return false if crosses_existing_wall_span?(wall_span)

    pawns.all? do |pawn|
      board.path_exists?(
        start_col: pawn.col,
        start_row: pawn.row,
        goal_row: winning_row_for?(pawn.player),
        extra_occupied_wall_wells: wall_span
      )
    end
  end

  def place_wall_in_well(wall, wall_well)
    place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)
  end

  def place_wall_in_well_with_side(wall, wall_well, preferred_side:)
    return false unless can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

    wall_span = board.wall_span_from(wall_well, preferred_side: preferred_side)
    wall.assign_to_wall_wells(wall_span)
    wall_span.each { |occupied_well| occupied_well.assign_wall(wall) }
    next_turn!
    true
  end

  private

  def adjacent?(from_col, from_row, to_col, to_row)
    ((from_col - to_col).abs + (from_row - to_row).abs) == 1
  end

  def legal_moves_for(pawn)
    orthogonal_neighbors(pawn.col, pawn.row).flat_map do |neighbor|
      next [] if board.path_blocked?(from_col: pawn.col, from_row: pawn.row, to_col: neighbor[:col], to_row: neighbor[:row])

      occupant = pawn_at(neighbor[:col], neighbor[:row])
      if occupant.nil?
        [neighbor]
      else
        jump_moves_for(pawn, occupant)
      end
    end
  end

  def pawn_at?(col, row)
    pawns.any? { |pawn| pawn.col == col && pawn.row == row }
  end

  def pawn_at(col, row)
    pawns.find { |pawn| pawn.col == col && pawn.row == row }
  end

  def jump_moves_for(pawn, blocking_pawn)
    dx = blocking_pawn.col - pawn.col
    dy = blocking_pawn.row - pawn.row
    jump_col = blocking_pawn.col + dx
    jump_row = blocking_pawn.row + dy

    if board.square_at(jump_col, jump_row) &&
       !board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: jump_col, to_row: jump_row) &&
       !pawn_at?(jump_col, jump_row)
      [{ col: jump_col, row: jump_row }]
    else
      diagonal_jump_moves_for(blocking_pawn, dx: dx, dy: dy)
    end
  end

  def diagonal_jump_moves_for(blocking_pawn, dx:, dy:)
    if dx == 0
      [
        { col: blocking_pawn.col - 1, row: blocking_pawn.row },
        { col: blocking_pawn.col + 1, row: blocking_pawn.row }
      ]
    else
      [
        { col: blocking_pawn.col, row: blocking_pawn.row - 1 },
        { col: blocking_pawn.col, row: blocking_pawn.row + 1 }
      ]
    end.select do |move|
      board.square_at(move[:col], move[:row]) &&
        !board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: move[:col], to_row: move[:row]) &&
        !pawn_at?(move[:col], move[:row])
    end
  end

  def orthogonal_neighbors(col, row)
    [
      { col: col + 1, row: row },
      { col: col - 1, row: row },
      { col: col, row: row + 1 },
      { col: col, row: row - 1 }
    ].select { |move| board.square_at(move[:col], move[:row]) }
  end

  def winning_row_for?(player)
    return board.size - 1 if player == players[0]

    0
  end

  def crosses_existing_wall_span?(wall_span)
    walls.any? do |existing_wall|
      next false unless existing_wall.placed?

      spans_cross?(wall_span, existing_wall.wall_wells)
    end
  end

  def spans_cross?(first_span, second_span)
    first_orientation = first_span.first.orientation
    second_orientation = second_span.first.orientation
    return false if first_orientation == second_orientation

    first_anchor = span_anchor(first_span)
    second_anchor = span_anchor(second_span)

    first_anchor[:col] == second_anchor[:col] &&
      first_anchor[:row] == second_anchor[:row]
  end

  def span_anchor(span)
    {
      col: span.first.col,
      row: span.first.row
    }
  end

  def build_walls
    walls = []
    player_bottom = players[0]
    player_top = players[1]

    WALLS_PER_LANE.times do |slot|
      walls << Wall.new(lane: :top, slot: slot, width: WALL_WIDTH, height: WALL_HEIGHT, color: WALL_COLOR, player: player_top)
      walls << Wall.new(lane: :bottom, slot: slot, width: WALL_WIDTH, height: WALL_HEIGHT, color: WALL_COLOR, player: player_bottom)
    end

    walls
  end
end
