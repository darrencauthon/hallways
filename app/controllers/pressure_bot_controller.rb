class PressureBotController < BotController
  MIN_THINK_TICKS = 8
  WALL_CHECKS_PER_TICK = 14
  WALL_OPPONENT_WEIGHT = 2.0
  WALL_SELF_WEIGHT = 1.2
  MOVE_IMPROVEMENT_WEIGHT = 1.5
  WALL_PATH_DEFICIT_WEIGHT = 0.25

  def next_action(args:, game:)
    return nil if game.winner

    begin_turn_if_needed(game)
    step_wall_scan(game) if @scan_mode == :wall_scan
    finalize_decision if @scan_mode == :decide
    thinking_tick!
    return { type: :thinking } if still_thinking?

    action = finalize_turn_action
    reset_strategy_state
    action
  end

  private

  def bot_name
    "Cowboy"
  end

  def begin_turn_if_needed(game)
    return unless begin_turn_thinking(game, min_ticks: MIN_THINK_TICKS)

    @game = game
    @my_pawn = current_player_pawn(game)
    @opponent_pawn = most_advanced_opponent_pawn(game)
    @wall_piece = current_player_wall_piece(game)
    @best_wall_candidate = nil
    @wall_candidates = []

    if @my_pawn.nil? || @opponent_pawn.nil?
      set_ready_action(nil)
      @scan_mode = :done
      return
    end

    @my_baseline_distance = distance_to_goal(
      game.board,
      @my_pawn.col,
      @my_pawn.row,
      @my_pawn.player,
      extra_occupied_wall_wells: nil
    )
    @opponent_baseline_distance = distance_to_goal(
      game.board,
      @opponent_pawn.col,
      @opponent_pawn.row,
      @opponent_pawn.player,
      extra_occupied_wall_wells: nil
    )
    @best_move_candidate = best_move_candidate(game, @my_pawn)

    if @wall_piece.nil?
      set_ready_action(@best_move_candidate && @best_move_candidate[:action])
      @scan_mode = :done
      return
    end

    @scan_mode = :wall_scan
    @wall_wells = game.board.wall_wells
    @wall_well_index = 0
    @wall_side_index = 0
  end

  def step_wall_scan(game)
    checks = 0
    while checks < WALL_CHECKS_PER_TICK && @wall_well_index < @wall_wells.length
      wall_well = @wall_wells[@wall_well_index]
      preferred_side = @wall_side_index.zero? ? :negative : :positive
      evaluate_wall_candidate(game, wall_well, preferred_side)
      advance_wall_cursor
      checks += 1
    end

    @scan_mode = :decide if @wall_well_index >= @wall_wells.length
  end

  def finalize_decision
    move_score = @best_move_candidate.nil? ? -9999.0 : @best_move_candidate[:score]
    wall_score = @best_wall_candidate.nil? ? -9999.0 : @best_wall_candidate[:score]
    path_deficit = (@my_baseline_distance || 0) - (@opponent_baseline_distance || 0)

    chosen_action =
      if wall_score > move_score
        @best_wall_candidate[:action]
      elsif wall_score == move_score && path_deficit > 0 && !@best_wall_candidate.nil?
        @best_wall_candidate[:action]
      else
        @best_move_candidate && @best_move_candidate[:action]
      end

    set_ready_action(chosen_action)
    @scan_mode = :done
  end

  def evaluate_wall_candidate(game, wall_well, preferred_side)
    return unless game.can_place_wall_in_well?(@wall_piece, wall_well, preferred_side: preferred_side)

    wall_span = game.board.wall_span_from(wall_well, preferred_side: preferred_side)
    return if wall_span.nil?

    opponent_after = distance_to_goal(
      game.board,
      @opponent_pawn.col,
      @opponent_pawn.row,
      @opponent_pawn.player,
      extra_occupied_wall_wells: wall_span
    )
    my_after = distance_to_goal(
      game.board,
      @my_pawn.col,
      @my_pawn.row,
      @my_pawn.player,
      extra_occupied_wall_wells: wall_span
    )
    return if opponent_after.nil? || my_after.nil?

    opponent_delta = opponent_after - (@opponent_baseline_distance || opponent_after)
    my_delta = my_after - (@my_baseline_distance || my_after)
    return if opponent_delta <= 0

    path_deficit = (@my_baseline_distance || my_after) - (@opponent_baseline_distance || opponent_after)
    score =
      (opponent_delta * WALL_OPPONENT_WEIGHT) -
      (my_delta * WALL_SELF_WEIGHT) +
      wall_position_bonus(wall_well) +
      (path_deficit * WALL_PATH_DEFICIT_WEIGHT)
    action = {
      type: :place_wall,
      wall: @wall_piece,
      wall_well: wall_well,
      preferred_side: preferred_side
    }

    candidate = { score: score, action: action }
    if @best_wall_candidate.nil? || score > @best_wall_candidate[:score]
      @best_wall_candidate = candidate
      @wall_candidates = [candidate]
    elsif score == @best_wall_candidate[:score]
      @wall_candidates << candidate
      @best_wall_candidate = @wall_candidates.sample
    end
  end

  def best_move_candidate(game, pawn)
    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    baseline = @my_baseline_distance || distance_to_goal(game.board, pawn.col, pawn.row, pawn.player, extra_occupied_wall_wells: nil)
    best_score = nil
    best_actions = []

    legal_moves.each do |move|
      move_distance = distance_to_goal(
        game.board,
        move[:col],
        move[:row],
        pawn.player,
        extra_occupied_wall_wells: nil
      )
      next if move_distance.nil?

      improvement = baseline - move_distance
      score = improvement * MOVE_IMPROVEMENT_WEIGHT
      action = {
        type: :move_pawn,
        pawn: pawn,
        col: move[:col],
        row: move[:row]
      }

      if best_score.nil? || score > best_score
        best_score = score
        best_actions = [{ score: score, action: action }]
      elsif score == best_score
        best_actions << { score: score, action: action }
      end
    end

    return nil if best_actions.empty?

    best_actions.sample
  end

  def wall_position_bonus(wall_well)
    center_col = 4.0
    center_row = 4.0
    dist = (wall_well.col - center_col).abs + (wall_well.row - center_row).abs
    [0.6 - (dist * 0.08), -0.6].max
  end

  def advance_wall_cursor
    if @wall_side_index.zero?
      @wall_side_index = 1
    else
      @wall_side_index = 0
      @wall_well_index += 1
    end
  end

  def reset_strategy_state
    @game = nil
    @scan_mode = nil
    @my_pawn = nil
    @opponent_pawn = nil
    @wall_piece = nil
    @my_baseline_distance = nil
    @opponent_baseline_distance = nil
    @best_move_candidate = nil
    @best_wall_candidate = nil
    @wall_candidates = nil
    @wall_wells = nil
    @wall_well_index = nil
    @wall_side_index = nil
  end
end
