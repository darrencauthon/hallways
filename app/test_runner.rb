require "app/screens/title_screen.rb"
require "app/tests/title_screen_test.rb"
require "app/screens/setup_screen.rb"
require "app/tests/setup_screen_test.rb"
require "app/screens/victory_screen.rb"
require "app/tests/victory_screen_test.rb"
require "app/tests/main_routing_test.rb"
require "app/models/pawn.rb"
require "app/renderers/pawn_renderer.rb"
require "app/tests/pawn_test.rb"
require "app/renderers/board_renderer.rb"
require "app/tests/board_renderer_test.rb"
require "app/models/wall.rb"
require "app/renderers/wall_renderer.rb"
require "app/tests/wall_renderer_test.rb"
require "app/models/game.rb"
require "app/tests/game_test.rb"
require "app/screens/game_screen.rb"
require "app/tests/game_screen_test.rb"

module TestRunner
  def self.run
    tests = discover_tests

    passed = 0
    failed = 0
    results_log = []
    assert = RunnerAssert.new

    puts "[TEST] Running #{tests.length} test(s)..."

    tests.each do |test|
      begin
        Object.new.send(test, nil, assert)
        passed += 1
        results_log << { name: test.to_s, status: :pass }
      rescue Exception => e
        failed += 1
        results_log << { name: test.to_s, status: :fail, message: e.message }
        puts "[FAIL] #{test}: #{e.message}"
      end
    end

    puts "[TEST] Summary: #{passed} passed, #{failed} failed"
    { passed: passed, failed: failed, results_log: results_log }
  end

  def self.discover_tests
    Object.new.private_methods
      .grep(/^test_/)
      .select { |method_name| test_in_app_file?(method_name) }
      .sort
  end

  def self.test_in_app_file?(method_name)
    location = Object.instance_method(method_name).source_location
    return false if location.nil?
    return false if location[0].nil?

    location[0].start_with?("app/")
  rescue Exception
    false
  end

  class RunnerAssert
    def equal!(expected, actual, message = nil)
      return if expected == actual

      if message
        raise message
      end

      raise "Expected #{expected.inspect}, got #{actual.inspect}"
    end
  end
end

def test_zero_equals_zero(args, assert)
  assert.equal! 0, 0, "Expected zero to equal zero."
end

def verify_custom_runner_writes_summary(args, assert)
  results = TestRunner.run
  write_custom_test_output(results)
  assert.equal! 0, results[:failed], "Custom runner detected failing tests."
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
