class BotController < NullController
  def bot_name
    "Bot"
  end

  private

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
end
