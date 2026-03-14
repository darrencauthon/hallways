require "app/test_runner.rb"
require "app/title_screen.rb"
require "app/game_screen.rb"

def tick(args)
  if test_mode?(args)
    run_tests_and_quit(args)
    return
  end

  if current_screen(args) == :title
    handle_title_action(args, title_screen(args).tick(args))
  elsif current_screen(args) == :game
    game_screen(args).tick(args)
  end
end

def test_mode?(args)
  command_line_args(args).include? "--test"
end

def command_line_args(args)
  if args.gtk.respond_to?(:argv) && args.gtk.argv
    args.gtk.argv
  elsif args.gtk.respond_to?(:cli_arguments) && args.gtk.cli_arguments
    args.gtk.cli_arguments
  else
    []
  end
end

def run_tests_and_quit(args)
  return if args.state.tests_finished

  begin
    results = TestRunner.run
    args.state.tests_failed = results[:failed] > 0
  rescue StandardError => e
    args.state.tests_failed = true
    puts "[TEST] Runner crashed: #{e.class}: #{e.message}"
  ensure
    args.state.tests_finished = true
    request_quit(args)
  end
end

def request_quit(args)
  if args.gtk.respond_to? :request_quit
    args.gtk.request_quit
  elsif $gtk && $gtk.respond_to?(:request_quit)
    $gtk.request_quit
  end
end

def title_screen(args)
  args.state.title_screen_instance ||= TitleScreen.new
end

def game_screen(args)
  args.state.game_screen_instance ||= GameScreen.new
end

def current_screen(args)
  args.state.screen_name ||= :title
end

def handle_title_action(args, action)
  if action == :start
    args.state.screen_name = :game
  elsif action == :quit
    request_quit(args)
  end
end
