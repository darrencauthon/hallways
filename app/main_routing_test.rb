require "app/main.rb"

def test_main_tick_renders_victory_screen_without_winner_name_exception(args, assert)
  fake_args = MainRoutingTestHelpers.build_victory_args("Player 1")

  tick(fake_args)

  assert.equal! :victory, fake_args.state.screen_name, "Expected tick to remain on the victory screen."
  winner_label = fake_args.outputs.labels.find { |label| label[:text] == "Player 1 Wins!" }
  assert.equal! false, winner_label.nil?, "Expected victory screen to render the winner label."
end

module MainRoutingTestHelpers
  def self.build_victory_args(winner_name)
    state = MainRoutingFakeState.new
    state.screen_name = :victory
    state.winner_name = winner_name
    state.victory_screen_instance = VictoryScreen.new

    key_down = FakeKeyDown.new(false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    inputs = FakeInputs.new(keyboard)
    outputs = FakeOutputs.new
    gtk = MainRoutingFakeGtk.new

    MainRoutingFakeArgs.new(inputs, outputs, state, gtk)
  end
end

class MainRoutingFakeState
  attr_accessor :screen_name, :winner_name, :victory_screen_instance, :game_screen_instance, :title_screen_instance
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
