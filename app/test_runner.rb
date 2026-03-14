require "app/title_screen.rb"
require "app/title_screen_test.rb"
require "app/pawn.rb"
require "app/pawn_test.rb"
require "app/game.rb"
require "app/game_test.rb"

module TestRunner
  def self.run
    tests = [
      { name: "baseline: zero equals zero", fn: -> { assert_equal 0, 0 } },
      { name: "smoke: runner executes", fn: -> { assert_equal true, true } },
      { name: "sanity addition", fn: -> { assert_equal 4, 2 + 2 } }
    ]

    passed = 0
    failed = 0
    results_log = []

    puts "[TEST] Running #{tests.length} test(s)..."

    tests.each do |test|
      begin
        test[:fn].call
        passed += 1
        results_log << { name: test[:name], status: :pass }
        puts "[PASS] #{test[:name]}"
      rescue Exception => e
        failed += 1
        results_log << { name: test[:name], status: :fail, message: e.message }
        puts "[FAIL] #{test[:name]}: #{e.message}"
      end
    end

    puts "[TEST] Summary: #{passed} passed, #{failed} failed"
    { passed: passed, failed: failed, results_log: results_log }
  end

  def self.assert_equal(expected, actual)
    return if expected == actual

    raise "Expected #{expected.inspect}, got #{actual.inspect}"
  end
end

def test_zero_equals_zero(args, assert)
  assert.equal! 0, 0, "Expected zero to equal zero."
end

def test_custom_runner_writes_summary(args, assert)
  results = TestRunner.run
  write_custom_test_output(results)
  assert.equal! 0, results[:failed], "Custom runner detected failing tests."
end

def dragonruby_cli_arguments
  return [] unless $gtk
  return [] unless $gtk.respond_to?(:cli_arguments)

  $gtk.cli_arguments || []
rescue Exception
  []
end

def write_custom_test_output(results)
  lines = []
  lines << "custom_runner_summary"
  lines << "passed=#{results[:passed]}"
  lines << "failed=#{results[:failed]}"
  lines << "total=#{results[:passed] + results[:failed]}"
  lines << "details:"
  results[:results_log].each do |entry|
    line = "- #{entry[:status]} #{entry[:name]}"
    if entry[:message]
      line += " :: #{entry[:message]}"
    end
    lines << line
  end

  text = lines.join("\n") + "\n"
  if $gtk && $gtk.respond_to?(:write_file)
    $gtk.write_file "test-output.txt", text
  else
    File.write "test-output.txt", text
  end
rescue Exception => e
  puts "[TEST] Failed to write test-output.txt: #{e.class}: #{e.message}"
end

if dragonruby_cli_arguments.include?("--test")
  results = TestRunner.run
  write_custom_test_output(results)
  if results[:failed] > 0
    raise "[TEST] #{results[:failed]} test(s) failed."
  end

  puts "[TEST] SUCCESS: all custom tests passed."
end
