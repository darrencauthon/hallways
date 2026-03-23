require "app/screens/title_screen.rb"
require "app/screens/setup_screen.rb"
require "app/screens/victory_screen.rb"
require "app/models/pawn.rb"
require "app/models/game.rb"
require "app/screens/game_screen.rb"

module PlayingRuntime
  SHOW_DEBUG_DIAGNOSTICS = false

  def self.tick(args)
    SharedRuntime.toggle_fullscreen_if_requested(args)
    SharedRuntime.take_screenshot_if_requested(args)

    if current_screen(args) == :title
      handle_title_action(args, title_screen(args).tick(args))
    elsif current_screen(args) == :setup
      handle_setup_action(args, setup_screen(args).tick(args))
    elsif current_screen(args) == :game
      handle_game_action(args, game_screen(args).tick(args))
    elsif current_screen(args) == :victory
      handle_victory_action(args, victory_screen(args).tick(args, winner_name: stored_winner_name(args)))
    end

    render_debug_diagnostics(args)
  end

  def self.title_screen(args)
    args.state.title_screen_instance ||= TitleScreen.new(can_continue_game: resumable_game_available?(args))
  end

  def self.game_screen(args)
    args.state.game_screen_instance ||= GameScreen.new
  end

  def self.setup_screen(args)
    args.state.setup_screen_instance ||= SetupScreen.new
  end

  def self.victory_screen(args)
    args.state.victory_screen_instance ||= VictoryScreen.new
  end

  def self.current_screen(args)
    args.state.screen_name ||= :title
  end

  def self.handle_title_action(args, action)
    if action == :continue_game
      args.state.title_screen_instance = TitleScreen.new
      args.state.screen_name = :game
    elsif action == :open_setup
      args.state.setup_screen_instance = SetupScreen.new
      args.state.screen_name = :setup
    elsif action == :quit
      SharedRuntime.request_quit(args)
    end
  end

  def self.handle_setup_action(args, action)
    return if action.nil?
    if action == :main_menu
      args.state.setup_screen_instance = SetupScreen.new
      args.state.title_screen_instance = TitleScreen.new(can_continue_game: resumable_game_available?(args))
      args.state.screen_name = :title
      return
    end
    return unless action[0] == :start_game

    start_new_game(
      args,
      player_count: action[1][:player_count] || action[1][:player_types].length,
      player_types: action[1][:player_types]
    )
  end

  def self.handle_game_action(args, action)
    return if action.nil?

    if action == :main_menu
      args.state.resumable_game_available = true
      args.state.title_screen_instance = TitleScreen.new(can_continue_game: true)
      args.state.screen_name = :title
    elsif action[0] == :victory
      args.state.resumable_game_available = false
      args.state.winner_name = action[1]
      args.state.screen_name = :victory
    end
  end

  def self.handle_victory_action(args, action)
    if action == :play_again
      start_new_game(
        args,
        player_count: args.state.game_player_count || 2,
        player_types: args.state.game_player_types || [:human, :human]
      )
    elsif action == :main_menu
      args.state.resumable_game_available = false
      args.state.title_screen_instance = TitleScreen.new
      args.state.screen_name = :title
    end
  end

  def self.start_new_game(args, player_count: 2, player_types: [:human, :human])
    args.state.resumable_game_available = false
    args.state.game_player_count = player_count
    args.state.game_player_types = player_types
    args.state.game_screen_instance = GameScreen.new(player_count: player_count, player_types: player_types)
    args.state.winner_name = nil
    args.state.screen_name = :game
  end

  def self.resumable_game_available?(args)
    !!args.state.resumable_game_available
  end

  def self.stored_winner_name(args)
    args.state.winner_name || "Unknown Player"
  end

  def self.render_debug_diagnostics(args)
    return unless SHOW_DEBUG_DIAGNOSTICS

    args.outputs.primitives << GTK.framerate_diagnostics_primitives
  end
end
