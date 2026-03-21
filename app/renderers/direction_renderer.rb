class DirectionRenderer
  ANGLES = {
    right: 0,
    down: 270,
    left: 180,
    up: 90
  }.freeze

  def render(args, x:, y:, size:, direction:, color:)
    render_target = args.outputs[render_target_name(size, color, direction)]
    render_target.w = size
    render_target.h = size
    render_target.clear_before_render = true
    render_target.labels << {
      x: size / 2,
      y: size / 2,
      text: ">",
      size_px: size,
      anchor_x: 0.5,
      anchor_y: 0.5,
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      **color
    }

    args.outputs.sprites << {
      x: x,
      y: y,
      w: size,
      h: size,
      path: render_target_name(size, color, direction),
      angle: arrow_angle(direction),
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5
    }
  end

  private

  def arrow_angle(direction)
    ANGLES[direction] || ANGLES[:up]
  end

  def render_target_name(size, color, direction)
    "direction-arrow-#{direction}-#{size}-#{color[:r]}-#{color[:g]}-#{color[:b]}-#{color[:a] || 255}"
  end
end
