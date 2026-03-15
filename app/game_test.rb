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

def test_game_initial_current_player_is_first_player(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! game.players[0], game.current_player, "Expected first turn to belong to Player 1."
end

def test_game_initial_has_no_winner(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! nil, game.winner, "Expected game to start without a winner."
end

def test_player_my_turn_initial_state(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! true, game.players[0].my_turn?, "Expected Player 1 to report true for my_turn? at game start."
  assert.equal! false, game.players[1].my_turn?, "Expected Player 2 to report false for my_turn? at game start."
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

def test_game_initial_walls_split_evenly_between_players(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  player_one = game.players[0]
  player_two = game.players[1]
  player_one_walls = game.walls.count { |wall| wall.player == player_one }
  player_two_walls = game.walls.count { |wall| wall.player == player_two }

  assert.equal! 10, player_one_walls, "Expected Player 1 to start with 10 walls."
  assert.equal! 10, player_two_walls, "Expected Player 2 to start with 10 walls."
end

def test_game_wall_lane_matches_player_side(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  player_one = game.players[0]
  player_two = game.players[1]
  top_walls_owned_by_player_two = game.walls.select { |wall| wall.lane == :top }.all? { |wall| wall.player == player_two }
  bottom_walls_owned_by_player_one = game.walls.select { |wall| wall.lane == :bottom }.all? { |wall| wall.player == player_one }

  assert.equal! true, top_walls_owned_by_player_two, "Expected top-lane walls to belong to Player 2."
  assert.equal! true, bottom_walls_owned_by_player_one, "Expected bottom-lane walls to belong to Player 1."
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

def test_game_initial_has_wall_wells(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 144, game.board.wall_wells.length, "Expected board to initialize with 144 wall wells."
end

def test_game_initial_wall_wells_split_evenly_between_orientations(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  horizontal_count = game.board.wall_wells.count { |wall_well| wall_well.orientation == :horizontal }
  vertical_count = game.board.wall_wells.count { |wall_well| wall_well.orientation == :vertical }

  assert.equal! 72, horizontal_count, "Expected 72 horizontal wall wells."
  assert.equal! 72, vertical_count, "Expected 72 vertical wall wells."
end

def test_game_place_wall_in_well_associates_both_sides(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls[0]
  wall_well = game.board.wall_wells[0]

  game.place_wall_in_well(wall, wall_well)

  assert.equal! wall_well, wall.wall_well, "Expected wall to reference assigned wall well."
  assert.equal! wall, wall_well.wall, "Expected wall well to reference assigned wall."
end

def test_game_next_turn_switches_current_player(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  game.next_turn!

  assert.equal! game.players[1], game.current_player, "Expected next_turn! to switch to Player 2."
end

def test_game_place_wall_in_well_advances_turn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells[0]

  game.place_wall_in_well(wall, wall_well)

  assert.equal! game.players[1], game.current_player, "Expected placing a wall to advance to Player 2."
end

def test_game_place_wall_in_well_does_not_advance_turn_when_invalid(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }

  game.place_wall_in_well(wall, nil)

  assert.equal! game.players[0], game.current_player, "Expected invalid wall placement to keep the current player."
end

def test_game_move_pawn_to_adjacent_square_advances_turn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]

  moved = game.move_pawn_to(pawn, 4, 1)

  assert.equal! true, moved, "Expected adjacent pawn move to succeed."
  assert.equal! 4, pawn.col, "Expected pawn column to remain the same after moving forward."
  assert.equal! 1, pawn.row, "Expected pawn row to update to the adjacent square."
  assert.equal! game.players[1], game.current_player, "Expected successful pawn move to advance the turn."
end

def test_game_move_pawn_to_sets_winner_on_far_side(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  game.pawns[1].move_to(3, 7)
  pawn.move_to(4, 7)

  moved = game.move_pawn_to(pawn, 4, 8)

  assert.equal! true, moved, "Expected winning pawn move to succeed."
  assert.equal! game.players[0], game.winner, "Expected Player 1 to win after reaching the far side."
  assert.equal! game.players[0], game.current_player, "Expected turn to stop advancing after a winning move."
end

def test_game_move_pawn_to_rejects_moves_after_winner_declared(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  game.pawns[1].move_to(3, 7)
  pawn.move_to(4, 7)
  game.move_pawn_to(pawn, 4, 8)

  moved = game.move_pawn_to(game.pawns[1], 4, 7)

  assert.equal! false, moved, "Expected pawn moves to be rejected after the game has a winner."
end

def test_game_move_pawn_to_rejects_non_adjacent_square(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]

  moved = game.move_pawn_to(pawn, 4, 2)

  assert.equal! false, moved, "Expected non-adjacent pawn move to fail."
  assert.equal! 0, pawn.row, "Expected pawn row to remain unchanged after invalid move."
  assert.equal! game.players[0], game.current_player, "Expected invalid pawn move to keep the current player."
end

def test_game_move_pawn_to_requires_players_turn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[1]

  moved = game.move_pawn_to(pawn, 4, 7)

  assert.equal! false, moved, "Expected pawn move to fail when it is not that player's turn."
  assert.equal! 8, pawn.row, "Expected pawn position to remain unchanged."
  assert.equal! game.players[0], game.current_player, "Expected current player to remain unchanged."
end

def test_game_move_pawn_to_rejects_occupied_square(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  other_pawn = game.pawns[1]
  other_pawn.move_to(4, 1)

  moved = game.move_pawn_to(pawn, 4, 1)

  assert.equal! false, moved, "Expected pawn move to fail when the target square is occupied."
  assert.equal! 0, pawn.row, "Expected pawn row to remain unchanged when the target square is occupied."
end

def test_game_move_pawn_to_rejects_move_blocked_by_horizontal_wall(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0
  end

  game.place_wall_in_well(wall, wall_well)
  game.next_turn!
  moved = game.move_pawn_to(pawn, 4, 1)

  assert.equal! false, moved, "Expected pawn move to fail when a horizontal wall blocks the path."
  assert.equal! 0, pawn.row, "Expected pawn row to remain unchanged when blocked by a wall."
end

def test_game_move_pawn_to_rejects_move_blocked_by_vertical_wall(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 4 && candidate.row == 8
  end

  game.place_wall_in_well(wall, wall_well)
  game.next_turn!
  moved = game.move_pawn_to(pawn, 5, 8)

  assert.equal! false, moved, "Expected pawn move to fail when a vertical wall blocks the path."
  assert.equal! 4, pawn.col, "Expected pawn column to remain unchanged when blocked by a wall."
end

def test_game_place_wall_in_well_rejects_placement_after_winner_declared(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  game.pawns[1].move_to(3, 7)
  pawn.move_to(4, 7)
  game.move_pawn_to(pawn, 4, 8)
  wall = game.walls.find { |candidate| candidate.player == game.players[0] && !candidate.placed? }
  wall_well = game.board.wall_wells[0]

  game.place_wall_in_well(wall, wall_well)

  assert.equal! nil, wall.wall_well, "Expected wall placement to be rejected after the game has a winner."
  assert.equal! nil, wall_well.wall, "Expected wall well to remain empty after the game has a winner."
end

def test_game_initial_pawn_positions(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  first = game.pawns[0]
  second = game.pawns[1]

  assert.equal! 4, first.col, "Expected first pawn to start in middle column."
  assert.equal! 0, first.row, "Expected first pawn to start on bottom row."
  assert.equal! 4, second.col, "Expected second pawn to start in middle column."
  assert.equal! 8, second.row, "Expected second pawn to start on top row."
end
