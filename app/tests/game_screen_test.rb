require "app/screens/game_screen.rb"

def test_game_screen_escape_returns_to_main_menu(args, assert)
  screen = GameScreen.new

  action = screen.tick(TitleScreenTestHelpers.build_fake_args(escape: true))

  assert.equal! :main_menu, action, "Expected Escape during a game to return to the main menu."
end
