require "app/screens/game_screen.rb"

def test_game_screen_escape_returns_to_main_menu(args, assert)
  screen = GameScreen.new

  action = screen.tick(TitleScreenTestHelpers.build_fake_args(escape: true))

  assert.equal! :main_menu, action, "Expected Escape during a game to return to the main menu."
end

def test_game_screen_skips_controller_actions_while_pawn_animation_in_progress(args, assert)
  screen = GameScreen.new
  controller = GameScreenTestFakeController.new
  fake_game = GameScreenTestFakeGame.new(controller)
  fake_args = GameScreenTestHelpers.build_fake_args_with_grid(tick_count: 10)

  screen.define_singleton_method(:game) { fake_game }
  screen.send(:start_pawn_move_animation, fake_args)

  screen.tick(fake_args)

  assert.equal! 0, controller.calls, "Expected controller actions to be blocked while pawn animation is playing."
end

module GameScreenTestHelpers
  def self.build_fake_args_with_grid(tick_count:)
    key_down = FakeKeyDown.new(false, false, false, false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    mouse = FakeMouse.new(nil, nil, false, false)
    inputs = FakeInputs.new(keyboard, mouse)
    outputs = FakeOutputs.new
    state = GameScreenTestFakeState.new(tick_count)
    grid = GameScreenTestFakeGrid.new

    GameScreenTestFakeArgs.new(inputs, outputs, state, grid)
  end
end

class GameScreenTestFakeController
  attr_reader :calls

  def initialize
    @calls = 0
  end

  def next_action(args:, game:)
    @calls += 1
    { type: :thinking }
  end
end

class GameScreenTestFakePlayer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class GameScreenTestFakeGame
  attr_reader :winner, :current_player

  def initialize(controller)
    @controller = controller
    @winner = nil
    @current_player = GameScreenTestFakePlayer.new("Bot 1")
  end

  def current_controller
    @controller
  end

  def sync_render_state(dragged_wall:, dragged_pawn:, dragged_pawn_offset_x:, dragged_pawn_offset_y:)
  end

  def render(args, board_x:, board_y:, wall_drop_target:, pawn_drop_target:)
  end
end

class GameScreenTestFakeGrid
  attr_reader :w

  def initialize
    @w = 1280
  end
end

class GameScreenTestFakeState
  attr_accessor :tick_count

  def initialize(tick_count)
    @tick_count = tick_count
  end
end

class GameScreenTestFakeArgs
  attr_reader :inputs, :outputs, :state, :grid

  def initialize(inputs, outputs, state, grid)
    @inputs = inputs
    @outputs = outputs
    @state = state
    @grid = grid
  end
end
