require "app/test_runner.rb"
require "app/title_screen.rb"

def tick(args)
  if test_mode?(args)
    run_tests_and_quit(args)
    return
  end

  title_screen(args).tick(args)
end

def test_mode?(args)
  command_line_args(args).include? "--test"
end

def command_line_args(args)
  if args.gtk.respond_to?(:argv) && args.gtk.argv
    args.gtk.argv
  elsif defined?(ARGV) && ARGV
    ARGV
  else
    []
  end
end

def run_tests_and_quit(args)
  return if args.state.tests_finished

  results = TestRunner.run
  args.state.tests_finished = true
  args.state.tests_failed = results[:failed] > 0

  request_quit(args)
end

def request_quit(args)
  if args.gtk.respond_to? :request_quit
    args.gtk.request_quit
  elsif defined?($gtk) && $gtk.respond_to?(:request_quit)
    $gtk.request_quit
  end
end

def title_screen(args)
  args.state.title_screen ||= TitleScreen.new
end
