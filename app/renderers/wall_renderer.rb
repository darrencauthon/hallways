class WallRenderer
  PLACE_ANIMATION_TICKS = 60

  def initialize(cell_size:, cell_gap:, board_pixel_size:)
    @cell_size = cell_size
    @cell_gap = cell_gap
    @board_pixel_size = board_pixel_size
    @wall_visual_states = {}
  end

  def render_placed_walls(args, game, board_x, board_y)
    game.walls.each do |wall|
      next unless wall.placed?

      target_rect = wall.placed_rect(
        board_x,
        board_y,
        cell_width: @cell_size,
        cell_height: @cell_size,
        cell_gap: @cell_gap
      )
      next if target_rect.nil?

      rect = animated_rect_for(args, wall, target_rect)
      wall.render(args, rect[:x], rect[:y], rect[:w], rect[:h])
    end
  end

  def render_wall_drop_target(args, board_x, board_y, placement)
    return if placement.nil?

    placement[:wall_span].each do |wall_well|
      rect = wall_well.rect(
        board_x,
        board_y,
        cell_width: @cell_size,
        cell_height: @cell_size,
        cell_gap: @cell_gap
      )

      args.outputs.borders << {
        x: rect[:x] - 2,
        y: rect[:y] - 2,
        w: rect[:w] + 4,
        h: rect[:h] + 4,
        r: 240,
        g: 60,
        b: 60
      }
    end
  end

  def render_reserve_walls(args, game, board_x, board_y, options = {})
    dragged_wall = options[:dragged_wall]
    dragged_rect = options[:dragged_rect]
    dragged_angle = options[:dragged_angle]
    hover_wall = options[:hover_wall]
    reserve_rects = game.reserve_wall_rects(args, board_x, board_y)

    game.walls.each do |wall|
      next if wall.placed?
      next if reserve_rects[wall].nil?

      rect = reserve_rects[wall]
      x = rect[:x]
      y = rect[:y]
      width = rect[:w]
      height = rect[:h]

      if wall == dragged_wall
        x = dragged_rect[:x]
        y = dragged_rect[:y]
        width = dragged_rect[:w]
        height = dragged_rect[:h]
      end

      if wall == dragged_wall && !dragged_angle.nil?
        render_rotated_dragged_wall(args, wall, x: x, y: y, width: width, height: height, angle: dragged_angle)
      else
        wall.render(args, x, y, width, height)
      end
      sync_reserve_wall_state(wall, x: x, y: y, w: width, h: height, dragged: wall == dragged_wall)
      draw_hover_border_if_needed(args, game, wall, x, y, width: width, height: height, hover_wall: hover_wall)
    end
  end

  private

  def animated_rect_for(args, wall, target_rect)
    state = @wall_visual_states[wall.object_id]
    if state.nil?
      @wall_visual_states[wall.object_id] = target_rect.merge(placed: true)
      return target_rect
    end

    if !state[:placed]
      if state[:dragged]
        state[:x] = target_rect[:x]
        state[:y] = target_rect[:y]
        state[:w] = target_rect[:w]
        state[:h] = target_rect[:h]
      else
        state[:start_x] = state[:x]
        state[:start_y] = state[:y]
        state[:start_w] = state[:w]
        state[:start_h] = state[:h]
        state[:target_x] = target_rect[:x]
        state[:target_y] = target_rect[:y]
        state[:target_w] = target_rect[:w]
        state[:target_h] = target_rect[:h]
        state[:start_tick] = tick_count(args)
      end
      state[:placed] = true
      state[:dragged] = false
    end

    if animation_active?(args, state)
      progress = animation_progress(args, state)
      state[:x] = lerp(state[:start_x], state[:target_x], progress)
      state[:y] = lerp(state[:start_y], state[:target_y], progress)
      state[:w] = lerp(state[:start_w], state[:target_w], progress)
      state[:h] = lerp(state[:start_h], state[:target_h], progress)
    else
      state[:x] = target_rect[:x]
      state[:y] = target_rect[:y]
      state[:w] = target_rect[:w]
      state[:h] = target_rect[:h]
    end

    {
      x: state[:x],
      y: state[:y],
      w: state[:w],
      h: state[:h]
    }
  end

  def sync_reserve_wall_state(wall, x:, y:, w:, h:, dragged:)
    @wall_visual_states[wall.object_id] = {
      x: x,
      y: y,
      w: w,
      h: h,
      placed: false,
      dragged: dragged
    }
  end

  def render_rotated_dragged_wall(args, wall, x:, y:, width:, height:, angle:)
    args.outputs.sprites << {
      x: x,
      y: y,
      w: width,
      h: height,
      path: :pixel,
      r: wall.color[0],
      g: wall.color[1],
      b: wall.color[2],
      angle: angle,
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5
    }
  end

  def draw_hover_border_if_needed(args, game, wall, x, y, width:, height:, hover_wall:)
    return unless wall.player == game.current_player
    return unless hover_wall == wall

    args.outputs.borders << {
      x: x - 1,
      y: y - 1,
      w: width + 2,
      h: height + 2,
      r: 240,
      g: 60,
      b: 60
    }
  end

  def animation_active?(args, state)
    return false if state[:start_tick].nil?

    (tick_count(args) - state[:start_tick]) < PLACE_ANIMATION_TICKS
  end

  def animation_progress(args, state)
    elapsed = tick_count(args) - state[:start_tick]
    progress = elapsed.to_f / PLACE_ANIMATION_TICKS
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
