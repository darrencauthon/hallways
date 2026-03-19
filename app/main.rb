require "app/runtime/shared_runtime.rb"
require "app/runtime/testing_runtime.rb"
require "app/runtime/playing_runtime.rb"

def tick(args)
  if TestingRuntime.cli_test_mode?(args)
    TestingRuntime.run_tests_and_quit(args)
    return
  end

  PlayingRuntime.tick(args)
end
