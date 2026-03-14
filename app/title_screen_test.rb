def test_title_screen_default_enter_starts(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :start, action, "Expected Enter on default selection to start."
end

def test_title_screen_down_then_enter_quits(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(down: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected Down then Enter to choose Quit."
end

def test_title_screen_up_wraps_to_quit(args, assert)
  screen = TitleScreen.new
  screen.tick(TitleScreenTestHelpers.build_fake_args(up: true))
  action = screen.tick(TitleScreenTestHelpers.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected Up from Start to wrap to Quit."
end

module TitleScreenTestHelpers
  def self.build_fake_args(options = {})
    up = options[:up] || false
    down = options[:down] || false
    enter = options[:enter] || false

    key_down = FakeKeyDown.new(up, down, enter)
    keyboard = FakeKeyboard.new(key_down)
    inputs = FakeInputs.new(keyboard)
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
  attr_reader :keyboard

  def initialize(keyboard)
    @keyboard = keyboard
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
