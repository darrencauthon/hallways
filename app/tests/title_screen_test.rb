def test_title_screen_default_enter_starts(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :open_setup, action, "Expected Enter on default selection to open setup."
end

def test_title_screen_continue_game_option_is_default_when_available(args, assert)
  screen = TitleScreen.new(can_continue_game: true)
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))

  assert.equal! :continue_game, action, "Expected Enter on default selection to continue the paused game."
end

def test_title_screen_down_then_enter_quits(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected selecting Quit then Enter to quit."
end

def test_title_screen_up_wraps_to_quit(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(up: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected Up from first option to wrap to Quit."
end

def test_title_screen_mouse_click_play(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(mouse_x: 640, mouse_y: 250, mouse_down: true))

  assert.equal! :open_setup, action, "Expected mouse click over Play to open setup."
end

def test_title_screen_renders_version_label(args, assert)
  screen = TitleScreen.new
  fake_args = TitleScreenTestHelpers.build_fake_args
  screen.tick(fake_args)

  version_label = fake_args.outputs.labels.find { |label| label[:text] == "v0.2.1" }
  assert.equal! false, version_label.nil?, "Expected title screen to render version label v0.2.1."
end

def test_title_screen_renders_continue_game_option_when_available(args, assert)
  screen = TitleScreen.new(can_continue_game: true)
  fake_args = TitleScreenTestHelpers.build_fake_args
  screen.tick(fake_args)

  continue_label = fake_args.outputs.labels.find { |label| label[:text].include?("Continue Game") }
  assert.equal! false, continue_label.nil?, "Expected title screen to render Continue Game when a paused game is available."
end

module TitleScreenTestHelpers
  def self.build_fake_args(options = {})
    up = options[:up] || false
    down = options[:down] || false
    left = options[:left] || false
    right = options[:right] || false
    enter = options[:enter] || false
    escape = options[:escape] || false
    mouse_x = options.key?(:mouse_x) ? options[:mouse_x] : nil
    mouse_y = options.key?(:mouse_y) ? options[:mouse_y] : nil
    mouse_down = options[:mouse_down] || false
    mouse_up = options[:mouse_up] || false

    key_down = FakeKeyDown.new(up, down, left, right, enter, escape)
    keyboard = FakeKeyboard.new(key_down)
    mouse = FakeMouse.new(mouse_x, mouse_y, mouse_down, mouse_up)
    inputs = FakeInputs.new(keyboard, mouse)
    outputs = FakeOutputs.new
    FakeArgs.new(inputs, outputs)
  end
end

class FakeKeyDown
  attr_reader :up, :down, :left, :right, :enter, :escape

  def initialize(up, down, left, right, enter, escape)
    @up = up
    @down = down
    @left = left
    @right = right
    @enter = enter
    @escape = escape
  end
end

class FakeKeyboard
  attr_reader :key_down

  def initialize(key_down)
    @key_down = key_down
  end
end

class FakeInputs
  attr_reader :keyboard, :mouse

  def initialize(keyboard, mouse = nil)
    @keyboard = keyboard
    @mouse = mouse
  end
end

class FakeMouse
  attr_reader :x, :y, :down, :up

  def initialize(x, y, down, up)
    @x = x
    @y = y
    @down = down
    @up = up
  end
end

class FakeOutputs
  attr_accessor :background_color, :labels

  def initialize
    @labels = []
  end
end

class FakeArgs
  attr_reader :inputs, :outputs

  def initialize(inputs, outputs)
    @inputs = inputs
    @outputs = outputs
  end
end
