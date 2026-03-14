module TestRunner
  module_function

  def run
    tests = [
      { name: "baseline: zero equals zero", fn: -> { assert_equal 0, 0 } },
      { name: "smoke: runner executes", fn: -> { assert_equal true, true } },
      { name: "sanity addition", fn: -> { assert_equal 4, 2 + 2 } },
      { name: "title: enter defaults to start", fn: -> { title_enter_defaults_to_start } },
      { name: "title: down then enter selects quit", fn: -> { title_down_then_enter_selects_quit } },
      { name: "title: up wraps and selects quit", fn: -> { title_up_wraps_and_selects_quit } }
    ]

    passed = 0
    failed = 0

    puts "[TEST] Running #{tests.length} test(s)..."

    tests.each do |test|
      begin
        test[:fn].call
        passed += 1
        puts "[PASS] #{test[:name]}"
      rescue Exception => e
        failed += 1
        puts "[FAIL] #{test[:name]}: #{e.message}"
      end
    end

    puts "[TEST] Summary: #{passed} passed, #{failed} failed"
    { passed: passed, failed: failed }
  end

  def assert_equal(expected, actual)
    return if expected == actual

    raise "Expected #{expected.inspect}, got #{actual.inspect}"
  end

  def title_enter_defaults_to_start
    screen = TitleScreen.new
    action = screen.tick(build_fake_args(enter: true))
    assert_equal :start, action
  end

  def title_down_then_enter_selects_quit
    screen = TitleScreen.new
    screen.tick(build_fake_args(down: true))
    action = screen.tick(build_fake_args(enter: true))
    assert_equal :quit, action
  end

  def title_up_wraps_and_selects_quit
    screen = TitleScreen.new
    screen.tick(build_fake_args(up: true))
    action = screen.tick(build_fake_args(enter: true))
    assert_equal :quit, action
  end

  def build_fake_args(up: false, down: false, enter: false, return_key: false)
    key_down = FakeKeyDown.new(up: up, down: down, enter: enter, return_key: return_key)
    keyboard = FakeKeyboard.new(key_down)
    inputs = FakeInputs.new(keyboard)
    outputs = FakeOutputs.new
    FakeArgs.new(inputs, outputs)
  end
end

def test_zero_equals_zero(args, assert)
  assert.equal! 0, 0, "Expected zero to equal zero."
end

def test_title_screen_default_enter_starts(args, assert)
  screen = TitleScreen.new
  action = screen.tick(TestRunner.build_fake_args(enter: true))
  assert.equal! :start, action, "Expected Enter on default selection to start."
end

def test_title_screen_down_then_enter_quits(args, assert)
  screen = TitleScreen.new
  screen.tick(TestRunner.build_fake_args(down: true))
  action = screen.tick(TestRunner.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected Down then Enter to choose Quit."
end

def test_title_screen_up_wraps_to_quit(args, assert)
  screen = TitleScreen.new
  screen.tick(TestRunner.build_fake_args(up: true))
  action = screen.tick(TestRunner.build_fake_args(enter: true))
  assert.equal! :quit, action, "Expected Up from Start to wrap to Quit."
end

class FakeKeyDown
  attr_reader :up, :down, :enter

  def initialize(up:, down:, enter:, return_key:)
    @up = up
    @down = down
    @enter = enter
    @return_key = return_key
  end

  define_method(:return) { @return_key }
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

def dragonruby_cli_arguments
  return [] unless $gtk
  return [] unless $gtk.respond_to?(:cli_arguments)

  $gtk.cli_arguments || []
rescue Exception
  []
end

if dragonruby_cli_arguments.include?("--test")
  results = TestRunner.run
  if results[:failed] > 0
    raise "[TEST] #{results[:failed]} test(s) failed."
  end

  puts "[TEST] SUCCESS: all custom tests passed."
end
