module TestRunner
  module_function

  def run
    tests = [
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
      rescue StandardError => e
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
