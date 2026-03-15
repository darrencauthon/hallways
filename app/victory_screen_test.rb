def test_victory_screen_default_enter_restarts(args, assert)
  screen = VictoryScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true), winner_name: "Player 1")

  assert.equal! :play_again, action, "Expected Enter on default selection to choose Play Again."
end

def test_victory_screen_down_then_enter_returns_to_main_menu(args, assert)
  screen = VictoryScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true), winner_name: "Player 1")
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true), winner_name: "Player 1")

  assert.equal! :main_menu, action, "Expected Down then Enter to choose Main Menu."
end

def test_victory_screen_up_wraps_to_main_menu(args, assert)
  screen = VictoryScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(up: true), winner_name: "Player 1")
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true), winner_name: "Player 1")

  assert.equal! :main_menu, action, "Expected Up from Play Again to wrap to Main Menu."
end
