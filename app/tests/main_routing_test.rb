require "app/main.rb"

def test_main_tick_renders_victory_screen_without_winner_name_exception(args, assert)
  fake_args = MainRoutingTestHelpers.build_victory_args("Player 1")

  tick(fake_args)

  assert.equal! :victory, fake_args.state.screen_name, "Expected tick to remain on the victory screen."
  winner_label = fake_args.outputs.labels.find { |label| label[:text] == "Player 1 Wins!" }
  assert.equal! false, winner_label.nil?, "Expected victory screen to render the winner label."
end

def test_main_tick_does_not_require_testing_runtime_for_normal_boot(args, assert)
  fake_args = MainRoutingTestHelpers.build_title_args

  assert.equal! nil, defined?(TestingRuntime), "Expected normal boot test to run without eagerly loading TestingRuntime."

  tick(fake_args)

  assert.equal! :title, fake_args.state.screen_name, "Expected normal boot to stay on the title screen."
  title_label = fake_args.outputs.labels.find { |label| label[:text] == "Hallways" }
  assert.equal! false, title_label.nil?, "Expected normal boot to render the title screen without TestingRuntime."
end

def test_handle_game_action_main_menu_exposes_continue_game(args, assert)
  fake_args = MainRoutingTestHelpers.build_title_args
  game_screen = Object.new
  fake_args.state.game_screen_instance = game_screen

  PlayingRuntime.handle_game_action(fake_args, :main_menu)

  assert.equal! :title, fake_args.state.screen_name, "Expected Escape from game to return to the title screen."
  assert.equal! true, fake_args.state.resumable_game_available, "Expected paused game state to be resumable."
  label_args = TitleScreenTestHelpers.build_fake_args
  fake_args.state.title_screen_instance.tick(label_args)
  continue_label = label_args.outputs.labels.find { |label| label[:text].include?("Continue Game") }
  assert.equal! false, continue_label.nil?, "Expected the title screen to show Continue Game after leaving an active match."
  assert.equal! game_screen, fake_args.state.game_screen_instance, "Expected paused game screen instance to be preserved."
end

def test_handle_title_action_continue_game_returns_to_existing_game(args, assert)
  fake_args = MainRoutingTestHelpers.build_title_args
  game_screen = Object.new
  fake_args.state.game_screen_instance = game_screen
  fake_args.state.resumable_game_available = true
  fake_args.state.title_screen_instance = TitleScreen.new(can_continue_game: true)
  fake_args.state.screen_name = :title

  PlayingRuntime.handle_title_action(fake_args, :continue_game)

  assert.equal! :game, fake_args.state.screen_name, "Expected Continue Game to return to the game screen."
  assert.equal! game_screen, fake_args.state.game_screen_instance, "Expected Continue Game to keep the existing game state."
end

module MainRoutingTestHelpers
  def self.build_victory_args(winner_name)
    state = MainRoutingFakeState.new
    state.screen_name = :victory
    state.winner_name = winner_name
    state.victory_screen_instance = VictoryScreen.new

    key_down = FakeKeyDown.new(false, false, false, false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    inputs = FakeInputs.new(keyboard)
    outputs = FakeOutputs.new
    gtk = MainRoutingFakeGtk.new

    MainRoutingFakeArgs.new(inputs, outputs, state, gtk)
  end

  def self.build_title_args
    state = MainRoutingFakeState.new
    state.screen_name = :title
    state.title_screen_instance = TitleScreen.new

    key_down = FakeKeyDown.new(false, false, false, false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    inputs = FakeInputs.new(keyboard)
    outputs = FakeOutputs.new
    gtk = MainRoutingFakeGtk.new

    MainRoutingFakeArgs.new(inputs, outputs, state, gtk)
  end
end

class MainRoutingFakeState
  attr_accessor :screen_name, :winner_name, :victory_screen_instance, :game_screen_instance, :title_screen_instance, :setup_screen_instance, :game_player_types, :resumable_game_available
end

class MainRoutingFakeGtk
  def argv
    []
  end

  def cli_arguments
    []
  end
end

class MainRoutingFakeArgs
  attr_reader :inputs, :outputs, :state, :gtk

  def initialize(inputs, outputs, state, gtk)
    @inputs = inputs
    @outputs = outputs
    @state = state
    @gtk = gtk
  end
end
