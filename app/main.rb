require "app/version.rb"
require "app/screens/title_screen.rb"
require "app/screens/setup_screen.rb"
require "app/screens/victory_screen.rb"
require "app/models/pawn.rb"
require "app/models/game.rb"
require "app/screens/game_screen.rb"

def tick(args)
  if cli_test_mode?(args)
    run_tests_and_quit(args)
    return
  end

  if current_screen(args) == :title
    handle_title_action(args, title_screen(args).tick(args))
  elsif current_screen(args) == :setup
    handle_setup_action(args, setup_screen(args).tick(args))
  elsif current_screen(args) == :game
    handle_game_action(args, game_screen(args).tick(args))
  elsif current_screen(args) == :victory
    handle_victory_action(args, victory_screen(args).tick(args, winner_name: stored_winner_name(args)))
  end
end

def cli_test_mode?(args)
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
    unless ensure_test_runner_loaded
      args.state.tests_failed = true
      puts "[TEST] Runner unavailable: app/test_runner.rb could not be loaded."
      return
    end

    results = TestRunner.run
    write_custom_test_output(results) if respond_to?(:write_custom_test_output)
    args.state.tests_failed = results[:failed] > 0
  rescue StandardError => e
    args.state.tests_failed = true
    puts "[TEST] Runner crashed: #{e.class}: #{e.message}"
  ensure
    args.state.tests_finished = true
    request_quit(args)
  end
end

def ensure_test_runner_loaded
  return true if defined?(TestRunner)

  require "app/test_runner.rb"
  true
rescue StandardError => e
  puts "[TEST] Failed to load app/test_runner.rb: #{e.class}: #{e.message}"
  false
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

def setup_screen(args)
  args.state.setup_screen_instance ||= SetupScreen.new
end

def victory_screen(args)
  args.state.victory_screen_instance ||= VictoryScreen.new
end

def current_screen(args)
  args.state.screen_name ||= :title
end

def handle_title_action(args, action)
  if action == :open_setup
    args.state.setup_screen_instance = SetupScreen.new
    args.state.screen_name = :setup
  elsif action == :quit
    request_quit(args)
  end
end

def handle_setup_action(args, action)
  return if action.nil?
  return unless action[0] == :start_game

  start_new_game(args, player_types: action[1][:player_types])
end

def handle_game_action(args, action)
  return if action.nil?

  if action[0] == :victory
    args.state.winner_name = action[1]
    args.state.screen_name = :victory
  end
end

def handle_victory_action(args, action)
  if action == :play_again
    start_new_game(args, player_types: args.state.game_player_types || [:human, :human])
  elsif action == :main_menu
    args.state.screen_name = :title
  end
end

def start_new_game(args, player_types: [:human, :human])
  args.state.game_player_types = player_types
  args.state.game_screen_instance = GameScreen.new(player_types: player_types)
  args.state.winner_name = nil
  args.state.screen_name = :game
end

def stored_winner_name(args)
  args.state.winner_name || "Unknown Player"
end
