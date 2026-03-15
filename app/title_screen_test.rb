def test_title_screen_default_enter_starts(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :start_human_vs_human, action, "Expected Enter on default selection to start Human vs Human."
end

def test_title_screen_down_then_enter_starts_human_vs_computer(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :start_human_vs_computer, action, "Expected Down then Enter to choose Human vs Computer."
end

def test_title_screen_down_twice_then_enter_quits(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
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

def test_title_screen_mouse_click_human_vs_computer(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(mouse_x: 640, mouse_y: 205, mouse_down: true))

  assert.equal! :start_human_vs_computer, action, "Expected mouse click over Human vs Computer to start that mode."
end

module TitleScreenTestHelpers
  def self.build_fake_args(options = {})
    up = options[:up] || false
    down = options[:down] || false
    enter = options[:enter] || false
    mouse_x = options.key?(:mouse_x) ? options[:mouse_x] : nil
    mouse_y = options.key?(:mouse_y) ? options[:mouse_y] : nil
    mouse_down = options[:mouse_down] || false
    mouse_up = options[:mouse_up] || false

    key_down = FakeKeyDown.new(up, down, enter)
    keyboard = FakeKeyboard.new(key_down)
    mouse = FakeMouse.new(mouse_x, mouse_y, mouse_down, mouse_up)
    inputs = FakeInputs.new(keyboard, mouse)
    outputs = FakeOutputs.new
    FakeArgs.new(inputs, outputs)
  end
end

class FakeKeyDown
  attr_reader :up, :down, :enter

  def initialize(up, down, enter)
    @up = up
    @down = down
    @enter = enter
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
