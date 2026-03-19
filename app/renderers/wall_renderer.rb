class WallRenderer
  def initialize(cell_size:, cell_gap:, board_pixel_size:)
    @cell_size = cell_size
    @cell_gap = cell_gap
    @board_pixel_size = board_pixel_size
  end

  def render_placed_walls(args, game, board_x, board_y)
    game.walls.each do |wall|
      next unless wall.placed?

      wall.render_on_board(
        args,
        board_x,
        board_y,
        cell_width: @cell_size,
        cell_height: @cell_size,
        cell_gap: @cell_gap
      )
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
      draw_hover_border_if_needed(args, game, wall, x, y, width: width, height: height, hover_wall: hover_wall)
    end
  end

  private

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
end
