require "app/models/player_palette.rb"

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

      target_rect = wall.placed_rect(board_x, board_y, @cell_size, @cell_size, @cell_gap)
      next if target_rect.nil?

      state = animated_state_for(args, wall, target_rect)
      render_wall_sprite(args, wall, center_x: state[:center_x], center_y: state[:center_y], angle: state[:angle])
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
        render_wall_sprite(
          args,
          wall,
          color: reserve_wall_color(game, wall),
          center_x: rect_center_x(x: x, w: width),
          center_y: rect_center_y(y: y, h: height),
          angle: dragged_angle
        )
      else
        wall.render(args, x, y, width, height, reserve_wall_color(game, wall))
      end
      sync_reserve_wall_state(wall, x: x, y: y, w: width, h: height, dragged: wall == dragged_wall)
      draw_hover_border_if_needed(args, game, wall, x, y, width: width, height: height, hover_wall: hover_wall)
    end
  end

  private

  def animated_state_for(args, wall, target_rect)
    state = @wall_visual_states[wall.object_id]
    if state.nil?
      @wall_visual_states[wall.object_id] = {
        center_x: rect_center_x(x: target_rect[:x], w: target_rect[:w]),
        center_y: rect_center_y(y: target_rect[:y], h: target_rect[:h]),
        angle: angle_for_rect(target_rect[:w], target_rect[:h]),
        placed: true
      }
      return @wall_visual_states[wall.object_id]
    end

    if !state[:placed]
      if state[:dragged]
        state[:center_x] = rect_center_x(x: target_rect[:x], w: target_rect[:w])
        state[:center_y] = rect_center_y(y: target_rect[:y], h: target_rect[:h])
        state[:angle] = angle_for_rect(target_rect[:w], target_rect[:h])
      else
        state[:start_center_x] = state[:center_x]
        state[:start_center_y] = state[:center_y]
        state[:start_angle] = state[:angle]
        state[:target_center_x] = rect_center_x(x: target_rect[:x], w: target_rect[:w])
        state[:target_center_y] = rect_center_y(y: target_rect[:y], h: target_rect[:h])
        state[:target_angle] = angle_for_rect(target_rect[:w], target_rect[:h])
        state[:start_tick] = tick_count(args)
      end
      state[:placed] = true
      state[:dragged] = false
    end

    if animation_active?(args, state)
      progress = animation_progress(args, state)
      state[:center_x] = lerp(state[:start_center_x], state[:target_center_x], progress)
      state[:center_y] = lerp(state[:start_center_y], state[:target_center_y], progress)
      state[:angle] = lerp_angle(state[:start_angle], state[:target_angle], progress)
    else
      state[:center_x] = rect_center_x(x: target_rect[:x], w: target_rect[:w])
      state[:center_y] = rect_center_y(y: target_rect[:y], h: target_rect[:h])
      state[:angle] = angle_for_rect(target_rect[:w], target_rect[:h])
    end

    state
  end

  def sync_reserve_wall_state(wall, x:, y:, w:, h:, dragged:)
    @wall_visual_states[wall.object_id] = {
      center_x: rect_center_x(x: x, w: w),
      center_y: rect_center_y(y: y, h: h),
      angle: angle_for_rect(w, h),
      placed: false,
      dragged: dragged
    }
  end

  def render_wall_sprite(args, wall, center_x:, center_y:, angle:, color: wall.color)
    render_target = args.outputs[wall_render_target_name(wall)]
    render_target.w = wall.width
    render_target.h = wall.width
    render_target.background_color = [0, 0, 0, 0]
    render_target.clear_before_render = true if render_target.respond_to?(:clear_before_render=)
    render_target.solids << {
      x: 0,
      y: (wall.width - wall.height) / 2,
      w: wall.width,
      h: wall.height,
      r: color[0],
      g: color[1],
      b: color[2]
    }

    args.outputs.sprites << {
      x: center_x - (wall.width / 2),
      y: center_y - (wall.width / 2),
      w: wall.width,
      h: wall.width,
      path: wall_render_target_name(wall),
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

  def reserve_wall_color(game, wall)
    player_index = game.players.index(wall.player) || 0
    player_fill = PlayerPalette::BOX_FILLS[player_index] || PlayerPalette::BOX_FILLS[0]
    [player_fill[:r], player_fill[:g], player_fill[:b]]
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

  def lerp_angle(from, to, progress)
    from + ((to - from) * progress)
  end

  def ease_out(progress)
    1 - ((1 - progress) * (1 - progress))
  end

  def angle_for_rect(width, height)
    height > width ? 90.0 : 0.0
  end

  def rect_center_x(x:, w:)
    x + (w / 2.0)
  end

  def rect_center_y(y:, h:)
    y + (h / 2.0)
  end

  def wall_render_target_name(wall)
    "wall_sprite_#{wall.object_id}"
  end

  def tick_count(args)
    return 0 unless args.respond_to?(:state) && args.state

    args.state.tick_count || 0
  end
end
