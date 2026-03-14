def test_game_initial_has_two_pawns(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 2, game.pawns.length, "Expected game to start with two pawns."
end

def test_game_initial_has_eighty_one_squares(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 81, game.wall.squares.length, "Expected game wall to have 9x9 squares."
end

def test_game_initial_has_wall(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! false, game.wall.nil?, "Expected game to initialize with a wall."
end

def test_game_initial_pawn_positions(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  first = game.pawns[0]
  second = game.pawns[1]

  assert.equal! 4, first.col, "Expected first pawn to start in middle column."
  assert.equal! 8, first.row, "Expected first pawn to start on bottom row."
  assert.equal! 4, second.col, "Expected second pawn to start in middle column."
  assert.equal! 0, second.row, "Expected second pawn to start on top row."
end
