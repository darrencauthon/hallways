def test_setup_screen_default_enter_on_play_starts_two_player_human_human(args, assert)
  screen = SetupScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! :start_game, action[0], "Expected Enter on Start Game row to start game."
  assert.equal! 2, action[1][:player_count], "Expected default player count to be 2."
  assert.equal! [:human, :human], action[1][:player_types], "Expected default setup to be Human/Human."
end

def test_setup_screen_toggle_player_two_to_random_bot(args, assert)
  screen = SetupScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(right: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! [:human, :random_bot], action[1][:player_types], "Expected toggled setup to keep Player 1 human and set Player 2 RandomBot."
end

def test_setup_screen_can_switch_to_four_player_mode(args, assert)
  screen = SetupScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(right: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! 4, action[1][:player_count], "Expected setup to switch to 4-player mode."
  assert.equal! [:human, :human, :human, :human], action[1][:player_types], "Expected four-player default types to be all human."
end

def test_setup_screen_four_player_mode_can_set_player_four_to_pressure_bot(args, assert)
  screen = SetupScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(right: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  4.times { screen.tick(TitleScreenTestHelpers.build_fake_args(right: true)) }
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! [:human, :human, :human, :pressure_bot], action[1][:player_types], "Expected Player 4 to cycle to PressureBot."
end

def test_setup_screen_mouse_click_start_game_starts_game(args, assert)
  screen = SetupScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(mouse_x: 1080, mouse_y: 360, mouse_down: true))

  assert.equal! :start_game, action[0], "Expected mouse click on Start Game row to start game."
end

def test_setup_screen_enter_on_main_menu_returns_main_menu(args, assert)
  screen = SetupScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! :main_menu, action, "Expected Enter on Main Menu row to return to the title screen."
end

def test_setup_screen_mouse_click_main_menu_returns_main_menu(args, assert)
  screen = SetupScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(mouse_x: 1080, mouse_y: 300, mouse_down: true))

  assert.equal! :main_menu, action, "Expected mouse click on Main Menu row to return to the title screen."
end
