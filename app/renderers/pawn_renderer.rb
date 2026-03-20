class PawnRenderer
  MOVE_ANIMATION_TICKS = 60

  def initialize(cell_size:, cell_gap:)
    @cell_size = cell_size
    @cell_gap = cell_gap
    @pawn_visual_states = {}
  end

  def render(args, game, board_x, board_y, dragged_pawn:, dragged_pawn_x:, dragged_pawn_y:)
    game.pawns.each do |pawn|
      target_x, target_y = pawn_screen_position(pawn, board_x, board_y)

      if pawn == dragged_pawn
        sync_dragged_pawn_state(pawn, dragged_pawn_x, dragged_pawn_y)
        pawn.render_at(args, dragged_pawn_x, dragged_pawn_y)
      else
        render_x, render_y = animated_position_for(
          args,
          pawn,
          target_x: target_x,
          target_y: target_y
        )
        pawn.render_at(args, render_x, render_y)
      end
    end
  end

  def render_drop_target(args, board_x, board_y, square)
    return if square.nil?

    x = board_x + (square.col * (@cell_size + @cell_gap))
    y = board_y + (square.row * (@cell_size + @cell_gap))

    args.outputs.borders << {
      x: x - 2,
      y: y - 2,
      w: @cell_size + 4,
      h: @cell_size + 4,
      r: 240,
      g: 60,
      b: 60
    }
  end

  def render_origin_highlight(args, board_x, board_y, square, color)
    return if square.nil?
    return if color.nil?

    x = board_x + (square.col * (@cell_size + @cell_gap))
    y = board_y + (square.row * (@cell_size + @cell_gap))

    args.outputs.borders << {
      x: x - 2,
      y: y - 2,
      w: @cell_size + 4,
      h: @cell_size + 4,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  private

  def animated_position_for(args, pawn, target_x:, target_y:)
    state = @pawn_visual_states[pawn.object_id]
    if state.nil?
      @pawn_visual_states[pawn.object_id] = {
        col: pawn.col,
        row: pawn.row,
        x: target_x,
        y: target_y
      }
      return [target_x, target_y]
    end

    if state[:col] != pawn.col || state[:row] != pawn.row
      if state[:dragged]
        state[:x] = target_x
        state[:y] = target_y
      else
        state[:start_x] = state[:x]
        state[:start_y] = state[:y]
        state[:target_x] = target_x
        state[:target_y] = target_y
        state[:start_tick] = tick_count(args)
      end
      state[:col] = pawn.col
      state[:row] = pawn.row
      state[:dragged] = false
    end

    if animation_active?(args, state)
      progress = animation_progress(args, state)
      state[:x] = lerp(state[:start_x], state[:target_x], progress)
      state[:y] = lerp(state[:start_y], state[:target_y], progress)
    else
      state[:x] = target_x
      state[:y] = target_y
    end

    [state[:x], state[:y]]
  end

  def sync_dragged_pawn_state(pawn, dragged_pawn_x, dragged_pawn_y)
    @pawn_visual_states[pawn.object_id] = {
      col: pawn.col,
      row: pawn.row,
      x: dragged_pawn_x,
      y: dragged_pawn_y,
      dragged: true
    }
  end

  def pawn_screen_position(pawn, board_x, board_y)
    cell_x = board_x + (pawn.col * (@cell_size + @cell_gap))
    cell_y = board_y + (pawn.row * (@cell_size + @cell_gap))

    [
      cell_x + ((pawn.cell_width - Pawn::PAWN_SIZE) / 2),
      cell_y + ((pawn.cell_height - Pawn::PAWN_SIZE) / 2)
    ]
  end

  def animation_active?(args, state)
    return false if state[:start_tick].nil?

    (tick_count(args) - state[:start_tick]) < MOVE_ANIMATION_TICKS
  end

  def animation_progress(args, state)
    elapsed = tick_count(args) - state[:start_tick]
    progress = elapsed.to_f / MOVE_ANIMATION_TICKS
    progress = 0.0 if progress < 0.0
    progress = 1.0 if progress > 1.0
    ease_out(progress)
  end

  def lerp(from, to, progress)
    from + ((to - from) * progress)
  end

  def ease_out(progress)
    1 - ((1 - progress) * (1 - progress))
  end

  def tick_count(args)
    return 0 unless args.respond_to?(:state) && args.state

    args.state.tick_count || 0
  end
end
