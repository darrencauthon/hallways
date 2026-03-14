module TestRunner
  module_function

  def run
    tests = [
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

if defined?(ARGV) && ARGV && ARGV.include?("--test")
  results = TestRunner.run
  if results[:failed] > 0
    raise "[TEST] #{results[:failed]} test(s) failed."
  end

  puts "[TEST] SUCCESS: smoke test and sanity test passed."
end
