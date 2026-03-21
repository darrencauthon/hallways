class PawnMoveFinder
  def moves_for(game:, pawn:)
    orthogonal_neighbors(game, pawn).flat_map do |neighbor|
      next [] if game.board.path_blocked?(from_col: pawn.col, from_row: pawn.row, to_col: neighbor[:col], to_row: neighbor[:row])

      occupant = pawn_at(game, neighbor[:col], neighbor[:row])
      if occupant.nil?
        [neighbor]
      else
        jump_moves_for(game, pawn, occupant)
      end
    end
  end

  private

  def pawn_at(game, col, row)
    game.pawns.find { |pawn| pawn.col == col && pawn.row == row }
  end

  def pawn_at?(game, col, row)
    !pawn_at(game, col, row).nil?
  end

  def jump_moves_for(game, pawn, blocking_pawn)
    dx = blocking_pawn.col - pawn.col
    dy = blocking_pawn.row - pawn.row
    jump_col = blocking_pawn.col + dx
    jump_row = blocking_pawn.row + dy

    if game.board.square_at(jump_col, jump_row) &&
       !game.board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: jump_col, to_row: jump_row) &&
       !pawn_at?(game, jump_col, jump_row)
      [{ col: jump_col, row: jump_row }]
    else
      diagonal_jump_moves_for(game, blocking_pawn, dx: dx, dy: dy)
    end
  end

  def diagonal_jump_moves_for(game, blocking_pawn, dx:, dy:)
    moves =
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
      end

    moves.select do |move|
      game.board.square_at(move[:col], move[:row]) &&
        !game.board.path_blocked?(from_col: blocking_pawn.col, from_row: blocking_pawn.row, to_col: move[:col], to_row: move[:row]) &&
        !pawn_at?(game, move[:col], move[:row])
    end
  end

  def orthogonal_neighbors(game, pawn)
    [
      { col: pawn.col + 1, row: pawn.row },
      { col: pawn.col - 1, row: pawn.row },
      { col: pawn.col, row: pawn.row + 1 },
      { col: pawn.col, row: pawn.row - 1 }
    ].select { |move| game.board.square_at(move[:col], move[:row]) }
  end
end
