class LastLineBotController < BotController
  WALL_CHECKS_PER_TICK = 12
  MIN_THINK_TICKS = 8

  def next_action(args:, game:)
    return nil if game.winner

    begin_turn_if_needed(game)
    step_blocking_scan(game) if @block_mode && !@scan_complete

    thinking_tick!
    return { type: :thinking } if still_thinking?

    action = finalize_turn_action
    reset_strategy_state
    action
  end

  private

  def begin_turn_if_needed(game)
    return unless begin_turn_thinking(game, min_ticks: MIN_THINK_TICKS)

    @scan_complete = false
    @block_mode = false
    @my_pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    @opponent_pawn = game.pawns.find { |candidate| candidate.player != game.current_player }

    if @my_pawn.nil?
      @scan_complete = true
      return
    end

    prepare_blocking_scan(game)
  end

  def prepare_blocking_scan(game)
    if !should_block_opponent?(@opponent_pawn)
      set_ready_action(best_move_action(game, @my_pawn))
      @scan_complete = true
      return
    end

    @wall_piece = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
    if @wall_piece.nil? || @opponent_pawn.nil?
      set_ready_action(best_move_action(game, @my_pawn))
      @scan_complete = true
      return
    end

    @baseline_distance = distance_to_goal_row(
      game.board,
      @opponent_pawn.col,
      @opponent_pawn.row,
      @opponent_pawn.player.winning_row,
      extra_occupied_wall_wells: nil
    )
    if @baseline_distance.nil?
      set_ready_action(best_move_action(game, @my_pawn))
      @scan_complete = true
      return
    end

    @block_mode = true
    @wall_wells = game.board.wall_wells
    @wall_well_index = 0
    @wall_side_index = 0
    @best_gain = 0
    @best_actions = []
  end

  def step_blocking_scan(game)
    checks = 0
    while checks < WALL_CHECKS_PER_TICK && @wall_well_index < @wall_wells.length
      wall_well = @wall_wells[@wall_well_index]
      preferred_side = @wall_side_index.zero? ? :negative : :positive

      evaluate_wall_candidate(game, wall_well, preferred_side)
      advance_wall_cursor
      checks += 1
    end

    return unless @wall_well_index >= @wall_wells.length

    set_ready_action(@best_actions.empty? ? best_move_action(game, @my_pawn) : @best_actions.sample)
    @scan_complete = true
  end

  def evaluate_wall_candidate(game, wall_well, preferred_side)
    return unless game.can_place_wall_in_well?(@wall_piece, wall_well, preferred_side: preferred_side)

    wall_span = game.board.wall_span_from(wall_well, preferred_side: preferred_side)
    return if wall_span.nil?

    candidate_distance = distance_to_goal_row(
      game.board,
      @opponent_pawn.col,
      @opponent_pawn.row,
      @opponent_pawn.player.winning_row,
      extra_occupied_wall_wells: wall_span
    )
    return if candidate_distance.nil?

    gain = candidate_distance - @baseline_distance
    return if gain <= 0

    action = {
      type: :place_wall,
      wall: @wall_piece,
      wall_well: wall_well,
      preferred_side: preferred_side
    }

    if gain > @best_gain
      @best_gain = gain
      @best_actions = [action]
    elsif gain == @best_gain
      @best_actions << action
    end
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
    @scan_complete = false
    @block_mode = false
    @my_pawn = nil
    @opponent_pawn = nil
    @wall_piece = nil
    @baseline_distance = nil
    @wall_wells = nil
    @wall_well_index = nil
    @wall_side_index = nil
    @best_gain = nil
    @best_actions = nil
  end

  def should_block_opponent?(opponent_pawn)
    return false if opponent_pawn.nil?

    rows_from_goal = (opponent_pawn.player.winning_row - opponent_pawn.row).abs
    rows_from_goal <= 2
  end

  def best_move_action(game, pawn)
    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    goal_row = game.current_player.winning_row
    best_distance = nil
    best_moves = []

    legal_moves.each do |move|
      distance = distance_to_goal_row(
        game.board,
        move[:col],
        move[:row],
        goal_row,
        extra_occupied_wall_wells: nil
      )
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

  def distance_to_goal_row(board, start_col, start_row, goal_row, extra_occupied_wall_wells:)
    return 0 if start_row == goal_row

    visited = {}
    frontier = [{ col: start_col, row: start_row, steps: 0 }]
    visited[key_for(start_col, start_row)] = true

    until frontier.empty?
      current = frontier.shift
      neighbors_for(
        board,
        current[:col],
        current[:row],
        extra_occupied_wall_wells: extra_occupied_wall_wells
      ).each do |neighbor|
        key = key_for(neighbor[:col], neighbor[:row])
        next if visited[key]

        return current[:steps] + 1 if neighbor[:row] == goal_row

        visited[key] = true
        frontier << {
          col: neighbor[:col],
          row: neighbor[:row],
          steps: current[:steps] + 1
        }
      end
    end

    nil
  end

  def neighbors_for(board, col, row, extra_occupied_wall_wells:)
    [
      { col: col + 1, row: row },
      { col: col - 1, row: row },
      { col: col, row: row + 1 },
      { col: col, row: row - 1 }
    ].select do |neighbor|
      board.square_at(neighbor[:col], neighbor[:row]) &&
        !board.path_blocked?(
          from_col: col,
          from_row: row,
          to_col: neighbor[:col],
          to_row: neighbor[:row],
          extra_occupied_wall_wells: extra_occupied_wall_wells
        )
    end
  end

  def key_for(col, row)
    "#{col},#{row}"
  end
end
