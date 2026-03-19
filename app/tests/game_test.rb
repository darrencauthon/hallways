def test_game_initial_has_two_pawns(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 2, game.pawns.length, "Expected game to start with two pawns."
end

def test_game_initial_has_two_players(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 2, game.players.length, "Expected game to start with two players."
end

def test_game_can_initialize_with_four_players(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  assert.equal! 4, game.players.length, "Expected 4-player game to have four players."
  assert.equal! 4, game.pawns.length, "Expected 4-player game to have four pawns."
end

def test_game_initial_player_names(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! "Player 1", game.players[0].name, "Expected first player name to be Player 1."
  assert.equal! "Player 2", game.players[1].name, "Expected second player name to be Player 2."
end

def test_game_four_player_initial_player_names(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  assert.equal! "Player 1", game.players[0].name, "Expected first player name to be Player 1."
  assert.equal! "Player 2", game.players[1].name, "Expected second player name to be Player 2."
  assert.equal! "Player 3", game.players[2].name, "Expected third player name to be Player 3."
  assert.equal! "Player 4", game.players[3].name, "Expected fourth player name to be Player 4."
end

def test_game_default_mode_uses_two_human_controllers(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! true, game.players[0].controller.is_a?(HumanController), "Expected Player 1 to use HumanController."
  assert.equal! true, game.players[1].controller.is_a?(HumanController), "Expected Player 2 to use HumanController in default mode."
end

def test_game_human_vs_computer_mode_uses_computer_player_two(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, mode: :human_vs_computer)

  assert.equal! true, game.players[0].controller.is_a?(HumanController), "Expected Player 1 to use HumanController."
  assert.equal! true, game.players[1].controller.is_a?(RandomBotController), "Expected Player 2 to use RandomBotController in Human vs Computer mode."
  assert.equal! "Bot 2", game.players[1].name, "Expected computer-controlled player to be named Bot 2."
end

def test_game_supports_explicit_player_type_configuration(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:random_bot, :human])

  assert.equal! "Bot 1", game.players[0].name, "Expected Player 1 name to become Bot 1 when configured as computer."
  assert.equal! "Player 2", game.players[1].name, "Expected Player 2 name to stay human when configured as human."
  assert.equal! true, game.players[0].controller.is_a?(RandomBotController), "Expected Player 1 controller to be RandomBot when configured."
  assert.equal! true, game.players[1].controller.is_a?(HumanController), "Expected Player 2 controller to be human when configured."
end

def test_game_supports_path_bot_configuration(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:path_bot, :human])

  assert.equal! true, game.players[0].controller.is_a?(PathBotController), "Expected Player 1 controller to be PathBot when configured."
  assert.equal! true, game.players[1].controller.is_a?(HumanController), "Expected Player 2 controller to be human when configured."
end

def test_game_supports_last_line_bot_configuration(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:last_line_bot, :human])

  assert.equal! true, game.players[0].controller.is_a?(LastLineBotController), "Expected Player 1 controller to be LastLineBot when configured."
  assert.equal! true, game.players[1].controller.is_a?(HumanController), "Expected Player 2 controller to be human when configured."
end

def test_game_supports_pressure_bot_configuration(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:pressure_bot, :human])

  assert.equal! true, game.players[0].controller.is_a?(PressureBotController), "Expected Player 1 controller to be PressureBot when configured."
  assert.equal! true, game.players[1].controller.is_a?(HumanController), "Expected Player 2 controller to be human when configured."
end

def test_game_supports_four_player_mixed_controller_configuration(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :random_bot, :path_bot, :pressure_bot])

  assert.equal! true, game.players[0].controller.is_a?(HumanController), "Expected Player 1 controller to be human."
  assert.equal! true, game.players[1].controller.is_a?(RandomBotController), "Expected Player 2 controller to be RandomBot."
  assert.equal! true, game.players[2].controller.is_a?(PathBotController), "Expected Player 3 controller to be PathBot."
  assert.equal! true, game.players[3].controller.is_a?(PressureBotController), "Expected Player 4 controller to be PressureBot."
end

def test_random_bot_controller_can_return_valid_wall_action(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:human, :random_bot])
  game.next_turn!
  controller = game.current_controller

  saw_thinking = false
  action = nil
  60.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected computer controller to return :thinking while it evaluates options."
  assert.equal! false, action.nil?, "Expected computer controller to eventually produce an action."

  if action[:type] == :move_pawn
    assert.equal! true, game.can_move_pawn_to?(action[:pawn], action[:col], action[:row]), "Expected computer pawn action to be valid."
  else
    assert.equal! :place_wall, action[:type], "Expected non-move computer action to be a wall placement."
    assert.equal! true, game.can_place_wall_in_well?(action[:wall], action[:wall_well], preferred_side: action[:preferred_side]), "Expected computer wall action to target a valid wall placement."
  end
end

def test_path_bot_controller_returns_valid_move_action(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:path_bot, :human])
  controller = game.current_controller

  saw_thinking = false
  action = nil
  40.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected PathBot to show a thinking phase before acting."
  assert.equal! :move_pawn, action[:type], "Expected PathBot to return a move action."
  assert.equal! true, game.can_move_pawn_to?(action[:pawn], action[:col], action[:row]), "Expected PathBot move action to be valid."
end

def test_last_line_bot_places_wall_when_opponent_is_two_rows_from_victory(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:last_line_bot, :human])
  controller = game.current_controller
  game.pawns[1].move_to(4, 2)

  saw_thinking = false
  action = nil
  80.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected LastLineBot to show a thinking phase before acting."
  assert.equal! :place_wall, action[:type], "Expected LastLineBot to place a wall when opponent is close to winning."
  assert.equal! true, game.can_place_wall_in_well?(action[:wall], action[:wall_well], preferred_side: action[:preferred_side]), "Expected LastLineBot wall action to be valid."
end

def test_last_line_bot_moves_when_opponent_not_near_victory(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:last_line_bot, :human])
  controller = game.current_controller

  saw_thinking = false
  action = nil
  80.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected LastLineBot to show a thinking phase before acting."
  assert.equal! :move_pawn, action[:type], "Expected LastLineBot to move when opponent is not near victory."
  assert.equal! true, game.can_move_pawn_to?(action[:pawn], action[:col], action[:row]), "Expected LastLineBot move action to be valid."
end

def test_pressure_bot_prefers_wall_when_opponent_is_close_and_ahead(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:pressure_bot, :human])
  controller = game.current_controller
  game.pawns[1].move_to(4, 2)

  saw_thinking = false
  action = nil
  120.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected PressureBot to show a thinking phase before acting."
  assert.equal! :place_wall, action[:type], "Expected PressureBot to place a wall when opponent is much closer to victory."
  assert.equal! true, game.can_place_wall_in_well?(action[:wall], action[:wall_well], preferred_side: action[:preferred_side]), "Expected PressureBot wall action to be valid."
end

def test_pressure_bot_returns_valid_action_when_opponent_not_close(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:pressure_bot, :human])
  controller = game.current_controller

  saw_thinking = false
  action = nil
  120.times do
    candidate = controller.next_action(args: nil, game: game)
    saw_thinking = true if candidate && candidate[:type] == :thinking
    if candidate && candidate[:type] != :thinking
      action = candidate
      break
    end
  end

  assert.equal! true, saw_thinking, "Expected PressureBot to show a thinking phase before acting."
  assert.equal! false, action.nil?, "Expected PressureBot to eventually return an action."

  if action[:type] == :move_pawn
    assert.equal! true, game.can_move_pawn_to?(action[:pawn], action[:col], action[:row]), "Expected PressureBot move action to be valid."
  else
    assert.equal! :place_wall, action[:type], "Expected non-move action to be a wall placement."
    assert.equal! true, game.can_place_wall_in_well?(action[:wall], action[:wall_well], preferred_side: action[:preferred_side]), "Expected PressureBot wall action to be valid."
  end
end

def test_game_initial_players_have_winning_rows(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! 8, game.players[0].winning_row, "Expected Player 1 winning row to be the top row."
  assert.equal! 0, game.players[1].winning_row, "Expected Player 2 winning row to be the bottom row."
end

def test_game_four_player_horizontal_players_have_winning_cols(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  assert.equal! 8, game.players[2].winning_col, "Expected Player 3 winning col to be right edge."
  assert.equal! 0, game.players[3].winning_col, "Expected Player 4 winning col to be left edge."
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

def test_player_turn_indicator_text_is_your_turn_for_human(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)

  assert.equal! "Your Turn", game.players[0].turn_indicator_text, "Expected active human player indicator text to be Your Turn."
  assert.equal! nil, game.players[1].turn_indicator_text, "Expected inactive player indicator text to be nil."
end

def test_player_turn_indicator_text_is_nil_for_bot_turn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_types: [:human, :random_bot])
  game.next_turn!

  assert.equal! nil, game.players[1].turn_indicator_text, "Expected active bot player indicator text to be nil."
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

def test_game_four_player_initial_has_twenty_walls(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  assert.equal! 20, game.walls.length, "Expected 4-player game to start with 20 reserve walls total."
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

def test_game_four_player_initial_walls_split_five_each(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  counts = game.players.map { |player| game.walls.count { |wall| wall.player == player } }
  assert.equal! [5, 5, 5, 5], counts, "Expected each player to start with 5 walls in 4-player mode."
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
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells[0]

  game.place_wall_in_well(wall, wall_well)

  assert.equal! wall_well, wall.wall_well, "Expected wall to reference assigned wall well."
  assert.equal! wall, wall_well.wall, "Expected wall well to reference assigned wall."
  assert.equal! wall, wall.wall_wells[1].wall, "Expected second wall well to reference the same wall."
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

def test_game_place_wall_in_well_requires_second_well_in_span(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 8 && candidate.row == 0
  end

  placed = game.place_wall_in_well(wall, wall_well)

  assert.equal! false, placed, "Expected wall placement to fail when there is no second wall well to cover."
  assert.equal! nil, wall.wall_well, "Expected wall to remain unassigned when there is no two-well span."
end

def test_game_place_wall_in_well_can_extend_to_negative_side(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0
  end

  placed = game.place_wall_in_well_with_side(wall, wall_well, preferred_side: :negative)

  assert.equal! true, placed, "Expected wall placement to succeed when extending to the negative side."
  assert.equal! [3, 4], wall.wall_wells.map(&:col), "Expected wall to cover the hovered wall well and the one to the left."
end

def test_game_place_wall_in_well_can_extend_to_positive_side(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0
  end

  placed = game.place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)

  assert.equal! true, placed, "Expected wall placement to succeed when extending to the positive side."
  assert.equal! [4, 5], wall.wall_wells.map(&:col), "Expected wall to cover the hovered wall well and the one to the right."
end

def test_game_place_wall_in_well_does_not_advance_turn_when_invalid(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player }

  game.place_wall_in_well(wall, nil)

  assert.equal! game.players[0], game.current_player, "Expected invalid wall placement to keep the current player."
end

def test_game_can_place_wall_in_well_rejects_wall_that_blocks_opponent_path(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  opponent_pawn = game.pawns[1]
  opponent_pawn.move_to(0, 8)

  first_wall = game.walls.find { |candidate| candidate.player == game.current_player }
  first_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 0 && candidate.row == 7
  end
  game.place_wall_in_well(first_wall, first_wall_well)
  game.next_turn!

  blocking_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  blocking_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 0 && candidate.row == 7
  end

  allowed = game.can_place_wall_in_well?(blocking_wall, blocking_wall_well)

  assert.equal! false, allowed, "Expected wall placement to be rejected when it removes the opponent's last path."
end

def test_game_place_wall_in_well_rejects_wall_that_blocks_opponent_path(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  opponent_pawn = game.pawns[1]
  opponent_pawn.move_to(0, 8)

  first_wall = game.walls.find { |candidate| candidate.player == game.current_player }
  first_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 0 && candidate.row == 7
  end
  game.place_wall_in_well(first_wall, first_wall_well)
  game.next_turn!

  blocking_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  blocking_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 0 && candidate.row == 7
  end

  placed = game.place_wall_in_well(blocking_wall, blocking_wall_well)

  assert.equal! false, placed, "Expected wall placement to fail when it removes the opponent's last path."
  assert.equal! nil, blocking_wall.wall_well, "Expected rejected wall placement to leave the wall unassigned."
  assert.equal! nil, blocking_wall_well.wall, "Expected rejected wall placement to leave the target wall well empty."
  assert.equal! game.players[0], game.current_player, "Expected rejected wall placement to keep the current player."
end

def test_game_can_place_wall_in_well_rejects_wall_that_blocks_current_players_path(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  current_pawn = game.pawns[0]
  current_pawn.move_to(0, 0)
  game.pawns[1].move_to(8, 8)

  first_wall = game.walls.find { |candidate| candidate.player == game.current_player }
  first_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 0 && candidate.row == 0
  end
  game.place_wall_in_well(first_wall, first_wall_well)
  game.next_turn!

  blocking_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  blocking_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 0 && candidate.row == 0
  end

  allowed = game.can_place_wall_in_well?(blocking_wall, blocking_wall_well)

  assert.equal! false, allowed, "Expected wall placement to be rejected when it removes the current player's last path."
end

def test_game_can_place_wall_in_well_rejects_crossing_existing_wall(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  first_wall = game.walls.find { |candidate| candidate.player == game.current_player }
  first_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 4
  end
  game.place_wall_in_well_with_side(first_wall, first_wall_well, preferred_side: :positive)
  game.next_turn!

  crossing_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  crossing_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 4 && candidate.row == 4
  end

  allowed = game.can_place_wall_in_well?(crossing_wall, crossing_well, preferred_side: :positive)

  assert.equal! false, allowed, "Expected wall placement to be rejected when it would cross an existing wall."
end

def test_game_place_wall_in_well_rejects_crossing_existing_wall(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  first_wall = game.walls.find { |candidate| candidate.player == game.current_player }
  first_wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :vertical && candidate.col == 4 && candidate.row == 4
  end
  game.place_wall_in_well_with_side(first_wall, first_wall_well, preferred_side: :positive)
  game.next_turn!

  crossing_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  crossing_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 4
  end

  placed = game.place_wall_in_well_with_side(crossing_wall, crossing_well, preferred_side: :positive)

  assert.equal! false, placed, "Expected crossing wall placement to fail."
  assert.equal! nil, crossing_wall.wall_well, "Expected rejected crossing wall to remain unassigned."
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

def test_game_move_pawn_to_allows_straight_jump_over_adjacent_pawn(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  other_pawn = game.pawns[1]
  other_pawn.move_to(4, 1)

  moved = game.move_pawn_to(pawn, 4, 2)

  assert.equal! true, moved, "Expected pawn to jump over an adjacent blocking pawn."
  assert.equal! 2, pawn.row, "Expected pawn to land beyond the blocking pawn."
  assert.equal! game.players[1], game.current_player, "Expected successful jump move to advance the turn."
end

def test_game_move_pawn_to_allows_diagonal_jump_when_straight_jump_blocked(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  other_pawn = game.pawns[1]
  other_pawn.move_to(4, 1)

  wall = game.walls.find { |candidate| candidate.player == game.current_player }
  wall_well = game.board.wall_wells.find do |candidate|
    candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 1
  end
  game.place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)
  game.next_turn!

  moved = game.move_pawn_to(pawn, 3, 1)

  assert.equal! true, moved, "Expected diagonal jump to be allowed when the straight jump is blocked."
  assert.equal! 3, pawn.col, "Expected pawn to move diagonally around the blocking pawn."
  assert.equal! 1, pawn.row, "Expected pawn to land beside the blocking pawn."
end

def test_game_move_pawn_to_rejects_diagonal_jump_when_straight_jump_is_open(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  pawn = game.pawns[0]
  other_pawn = game.pawns[1]
  other_pawn.move_to(4, 1)

  moved = game.move_pawn_to(pawn, 3, 1)

  assert.equal! false, moved, "Expected diagonal move to be rejected while a straight jump is available."
  assert.equal! 4, pawn.col, "Expected pawn column to remain unchanged after invalid diagonal move."
  assert.equal! 0, pawn.row, "Expected pawn row to remain unchanged after invalid diagonal move."
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
    candidate.orientation == :vertical && candidate.col == 4 && candidate.row == 7
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

def test_game_four_player_initial_pawn_positions(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48, player_count: 4, player_types: [:human, :human, :human, :human])

  assert.equal! [4, 0], [game.pawns[0].col, game.pawns[0].row], "Expected Player 1 pawn at bottom center."
  assert.equal! [4, 8], [game.pawns[1].col, game.pawns[1].row], "Expected Player 2 pawn at top center."
  assert.equal! [0, 4], [game.pawns[2].col, game.pawns[2].row], "Expected Player 3 pawn at left center."
  assert.equal! [8, 4], [game.pawns[3].col, game.pawns[3].row], "Expected Player 4 pawn at right center."
end
