module TestingRuntime
  def self.cli_test_mode?(args)
    SharedRuntime.command_line_args(args).include? "--test"
  end

  def self.run_tests_and_quit(args)
    return if args.state.tests_finished

    begin
      unless ensure_test_runner_loaded
        args.state.tests_failed = true
        puts "[TEST] Runner unavailable: app/test_runner.rb could not be loaded."
        return
      end

      results = TestRunner.run
      if Object.private_method_defined?(:write_custom_test_output)
        Object.new.send(:write_custom_test_output, results)
      end
      args.state.tests_failed = results[:failed] > 0
    rescue StandardError => e
      args.state.tests_failed = true
      puts "[TEST] Runner crashed: #{e.class}: #{e.message}"
    ensure
      args.state.tests_finished = true
      SharedRuntime.request_quit(args)
    end
  end

  def self.ensure_test_runner_loaded
    return true if defined?(TestRunner)

    require "app/test_runner.rb"
    true
  rescue StandardError => e
    puts "[TEST] Failed to load app/test_runner.rb: #{e.class}: #{e.message}"
    false
  end
end
