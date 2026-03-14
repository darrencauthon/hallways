def test_game_initial_has_two_pawns(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 2, game.pawns.length, "Expected game to start with two pawns."
end

def test_game_initial_has_two_players(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 2, game.players.length, "Expected game to start with two players."
end

def test_game_initial_player_names(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! "Player 1", game.players[0].name, "Expected first player name to be Player 1."
  assert.equal! "Player 2", game.players[1].name, "Expected second player name to be Player 2."
end

def test_game_players_associated_with_pawns(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! game.players[0], game.pawns[0].player, "Expected pawn 1 to be associated with Player 1."
  assert.equal! game.players[1], game.pawns[1].player, "Expected pawn 2 to be associated with Player 2."
end

def test_game_initial_has_twenty_walls(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 20, game.walls.length, "Expected game to start with 20 reserve walls."
end

def test_game_initial_walls_split_evenly_between_lanes(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  top_count = game.walls.count { |wall| wall.lane == :top }
  bottom_count = game.walls.count { |wall| wall.lane == :bottom }

  assert.equal! 10, top_count, "Expected 10 top-lane walls."
  assert.equal! 10, bottom_count, "Expected 10 bottom-lane walls."
end

def test_game_initial_has_eighty_one_squares(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 81, game.board.squares.length, "Expected game board to have 9x9 squares."
end

def test_game_initial_has_board(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! false, game.board.nil?, "Expected game to initialize with a board."
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
