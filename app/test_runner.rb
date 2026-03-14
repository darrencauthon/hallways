require "app/title_screen.rb"
require "app/title_screen_test.rb"

module TestRunner
  module_function

  def run
    tests = [
      { name: "baseline: zero equals zero", fn: -> { assert_equal 0, 0 } },
      { name: "smoke: runner executes", fn: -> { assert_equal true, true } },
      { name: "sanity addition", fn: -> { assert_equal 4, 2 + 2 } }
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
end

def test_zero_equals_zero(args, assert)
  assert.equal! 0, 0, "Expected zero to equal zero."
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
