class PathBotController < BotController
  MIN_THINK_TICKS = 6

  def next_action(args:, game:)
    return nil if game.winner

    begin_turn_if_needed(game)
    thinking_tick!
    return { type: :thinking } if still_thinking?

    finalize_turn_action
  end

  private

  def begin_turn_if_needed(game)
    return unless begin_turn_thinking(game, min_ticks: MIN_THINK_TICKS)

    set_ready_action(best_move_action(game))
  end

  def best_move_action(game)
    pawn = current_player_pawn(game)
    return nil if pawn.nil?

    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    current_player = game.current_player
    best_distance = nil
    best_moves = []

    legal_moves.each do |move|
      distance = distance_to_goal(game.board, move[:col], move[:row], current_player, extra_occupied_wall_wells: nil)
      next if distance.nil?

      if best_distance.nil? || distance < best_distance
        best_distance = distance
        best_moves = [move]
      elsif distance == best_distance
        best_moves << move
      end
    end

    chosen_move = (best_moves.empty? ? legal_moves : best_moves).sample
    {
      type: :move_pawn,
      pawn: pawn,
      col: chosen_move[:col],
      row: chosen_move[:row]
    }
  end

end
