require "app/test_runner.rb"

def tick(args)
  if test_mode?(args)
    run_tests_and_quit(args)
    return
  end

  render_title_screen(args)
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

def render_title_screen(args)
  args.outputs.background_color = [20, 20, 28]
  args.outputs.labels << {
    x: 640,
    y: 380,
    text: "Hallways",
    alignment_enum: 1,
    size_enum: 6,
    r: 240,
    g: 240,
    b: 240
  }

  args.outputs.labels << {
    x: 640,
    y: 330,
    text: "DragonRuby + Quoridor prototype",
    alignment_enum: 1,
    size_enum: 2,
    r: 180,
    g: 180,
    b: 190
  }
end
