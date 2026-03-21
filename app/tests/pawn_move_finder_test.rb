def test_pawn_move_finder_returns_opening_move_for_current_pawn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  move_finder = PawnMoveFinder.new

  moves = move_finder.moves_for(game: game, pawn: pawn)

  assert.equal! true, moves.include?({ col: 4, row: 1 }), "Expected the move finder to include the forward opening move for the current pawn."
  assert.equal! true, moves.include?({ col: 3, row: 0 }), "Expected the move finder to include the left opening move for the current pawn."
  assert.equal! true, moves.include?({ col: 5, row: 0 }), "Expected the move finder to include the right opening move for the current pawn."
end

def test_pawn_move_finder_returns_straight_jump_over_adjacent_pawn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  game.pawns[1].move_to(4, 1)
  move_finder = PawnMoveFinder.new

  moves = move_finder.moves_for(game: game, pawn: pawn)

  assert.equal! true, moves.include?({ col: 4, row: 2 }), "Expected move finder to include the straight jump over an adjacent pawn."
end

def test_pawn_move_finder_returns_diagonal_moves_when_straight_jump_is_blocked(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  game.pawns[1].move_to(4, 1)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 1 }
  game.place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)
  game.next_turn!
  move_finder = PawnMoveFinder.new

  moves = move_finder.moves_for(game: game, pawn: pawn)

  assert.equal! true, moves.include?({ col: 3, row: 1 }), "Expected move finder to include left diagonal jump when the straight jump is blocked."
  assert.equal! true, moves.include?({ col: 5, row: 1 }), "Expected move finder to include right diagonal jump when the straight jump is blocked."
end
