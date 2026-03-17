class RandomBotController < BotController
  WALL_CHECKS_PER_TICK = 12
  MIN_THINK_TICKS = 6

  def next_action(args:, game:)
    return nil if game.winner

    begin_turn_if_needed(game)
    step_wall_scan(game) if bot_waiting_for_action?
    thinking_tick!
    return { type: :thinking } if still_thinking?

    action = finalize_turn_action
    reset_strategy_state
    action
  end

  def thinking?
    still_thinking?
  end

  private

  def bot_name
    "RandomBot"
  end

  def begin_turn_if_needed(game)
    return unless begin_turn_thinking(game, min_ticks: MIN_THINK_TICKS)

    @pawn_options = pawn_actions(game)
    @wall_options = []
    @wall_wells = game.board.wall_wells
    @wall_well_index = 0
    @wall_side_index = 0
    @wall_piece = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }

    step_wall_scan(game)
  end

  def step_wall_scan(game)
    checks = 0
    while checks < WALL_CHECKS_PER_TICK && @wall_well_index < @wall_wells.length
      wall_well = @wall_wells[@wall_well_index]
      preferred_side = @wall_side_index.zero? ? :negative : :positive
      if !@wall_piece.nil? && game.can_place_wall_in_well?(@wall_piece, wall_well, preferred_side: preferred_side)
        @wall_options << {
          type: :place_wall,
          wall: @wall_piece,
          wall_well: wall_well,
          preferred_side: preferred_side
        }
      end

      if @wall_side_index.zero?
        @wall_side_index = 1
      else
        @wall_side_index = 0
        @wall_well_index += 1
      end
      checks += 1
    end

    finalize_action if @wall_well_index >= @wall_wells.length
  end

  def finalize_action
    return if action_ready?
    if @pawn_options.empty? && @wall_options.empty?
      set_ready_action(nil)
      return
    end

    if @pawn_options.empty?
      set_ready_action(@wall_options.sample)
    elsif @wall_options.empty?
      set_ready_action(@pawn_options.sample)
    else
      chosen_pool = [@pawn_options, @wall_options].sample
      set_ready_action(chosen_pool.sample)
    end
  end

  def reset_strategy_state
    @pawn_options = nil
    @wall_options = nil
    @wall_wells = nil
    @wall_well_index = nil
    @wall_side_index = nil
    @wall_piece = nil
  end

  def pawn_actions(game)
    pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return [] if pawn.nil?

    game.board.squares.filter_map do |square|
      next nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

      {
        type: :move_pawn,
        pawn: pawn,
        col: square.col,
        row: square.row
      }
    end
  end
end
