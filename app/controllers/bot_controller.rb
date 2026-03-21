require "app/models/path_distance_calculator.rb"
require "app/models/pawn_move_finder.rb"

class BotController < NullController
  def bot_name
    "Bot"
  end

  private

  def current_player_pawn(game)
    game.pawns.find { |candidate| candidate.player == game.current_player }
  end

  def current_player_wall_piece(game)
    game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  end

  def legal_pawn_moves(game, pawn)
    legal_pawn_move_finder.moves_for(game: game, pawn: pawn)
  end

  def distance_to_goal(board, start_col, start_row, player, extra_occupied_wall_wells: nil)
    path_distance_calculator.shortest_distance_to_goal(
      board: board,
      start_col: start_col,
      start_row: start_row,
      player: player,
      extra_occupied_wall_wells: extra_occupied_wall_wells
    )
  end

  def most_advanced_opponent_pawn(game)
    candidates = game.pawns.select { |candidate| candidate.player != game.current_player }
    return nil if candidates.empty?

    candidates.min_by do |pawn|
      distance_to_goal(game.board, pawn.col, pawn.row, pawn.player, extra_occupied_wall_wells: nil) || 9_999
    end
  end

  def begin_turn_thinking(game, min_ticks:)
    return false if @active_player == game.current_player

    @active_player = game.current_player
    @think_ticks_remaining = min_ticks
    @ready_action = nil
    @action_ready = false
    true
  end

  def set_ready_action(action)
    @ready_action = action
    @action_ready = true
  end

  def action_ready?
    @action_ready == true
  end

  def bot_waiting_for_action?
    !action_ready?
  end

  def thinking_tick!
    @think_ticks_remaining -= 1 if @think_ticks_remaining && @think_ticks_remaining > 0
  end

  def still_thinking?
    bot_waiting_for_action? || (@think_ticks_remaining && @think_ticks_remaining > 0)
  end

  def finalize_turn_action
    action = @ready_action
    reset_bot_turn_state
    action
  end

  def reset_bot_turn_state
    @active_player = nil
    @think_ticks_remaining = 0
    @ready_action = nil
    @action_ready = false
  end

  def path_distance_calculator
    @path_distance_calculator ||= PathDistanceCalculator.new
  end

  def legal_pawn_move_finder
    @legal_pawn_move_finder ||= PawnMoveFinder.new
  end
end
