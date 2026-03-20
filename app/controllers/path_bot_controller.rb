require "app/models/path_distance_calculator.rb"

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
    pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return nil if pawn.nil?

    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    current_player = game.current_player
    best_distance = nil
    best_moves = []

    legal_moves.each do |move|
      distance = distance_to_goal(game.board, move[:col], move[:row], current_player)
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

  def legal_pawn_moves(game, pawn)
    game.board.squares.filter_map do |square|
      next nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

      { col: square.col, row: square.row }
    end
  end

  def distance_to_goal(board, start_col, start_row, player)
    path_distance_calculator.shortest_distance_to_goal(
      board: board,
      start_col: start_col,
      start_row: start_row,
      player: player,
      extra_occupied_wall_wells: nil
    )
  end

  def path_distance_calculator
    @path_distance_calculator ||= PathDistanceCalculator.new
  end
end
