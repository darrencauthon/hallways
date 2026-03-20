require "app/runtime/shared_runtime.rb"
require "app/runtime/playing_runtime.rb"

def tick(args)
  if test_mode_requested?(args)
    run_testing_runtime(args)
    return
  end

  PlayingRuntime.tick(args)
end

def test_mode_requested?(args)
  SharedRuntime.command_line_args(args).include? "--test"
end

def run_testing_runtime(args)
  require "app/runtime/testing_runtime.rb"
  TestingRuntime.run_tests_and_quit(args)
end
