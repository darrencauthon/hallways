require "app/renderers/direction_renderer.rb"

class PlayerBoxRenderer
  BOX_W = 220
  AVATAR_MARGIN_X = 12
  AVATAR_MARGIN_TOP = 10
  AVATAR_SCALE = 0.72
  TITLE_GAP = 14
  SUBTITLE_GAP = 8
  BOTTOM_PADDING = 14
  BORDER = { r: 88, g: 94, b: 110 }.freeze
  ACTIVE_BORDER = { r: 255, g: 215, b: 120 }.freeze
  AVATAR_FILL = { r: 16, g: 18, b: 22 }.freeze
  WIN_LABEL_RIGHT_MARGIN = 37
  WIN_ROW_Y_OFFSET = 116
  WIN_ARROW_RIGHT_MARGIN = 13
  WIN_ARROW_SIZE = 28

  def self.box_width
    BOX_W
  end

  def self.avatar_size
    ((BOX_W - (AVATAR_MARGIN_X * 2)) * AVATAR_SCALE).to_i
  end

  def self.box_height
    AVATAR_MARGIN_TOP + avatar_size + TITLE_GAP + 14 + SUBTITLE_GAP + 14 + BOTTOM_PADDING
  end

  def render(args, x:, y:, fill_color:, selected:, title:, title_size_enum:, title_color:, subtitle:, subtitle_size_enum:, subtitle_color:, meta_label: nil, meta_label_size_enum: nil, meta_label_color: nil, meta_value: nil, meta_value_size_enum: nil, meta_value_color: nil, secondary_meta_label: nil, secondary_meta_label_size_enum: nil, secondary_meta_label_color: nil, secondary_meta_value: nil, secondary_meta_value_size_enum: nil, secondary_meta_value_color: nil, tertiary_meta_label: nil, tertiary_meta_label_size_enum: nil, tertiary_meta_label_color: nil, arrow_direction: nil, arrow_color: nil)
    border_color = selected ? ACTIVE_BORDER : BORDER
    avatar_x = x + AVATAR_MARGIN_X
    avatar_y = y + self.class.box_height - AVATAR_MARGIN_TOP - self.class.avatar_size
    title_y = avatar_y - TITLE_GAP
    subtitle_y = title_y - SUBTITLE_GAP - 14

    args.outputs.solids << {
      x: x,
      y: y,
      w: self.class.box_width,
      h: self.class.box_height,
      **fill_color
    }

    args.outputs.solids << {
      x: avatar_x,
      y: avatar_y,
      w: self.class.avatar_size,
      h: self.class.avatar_size,
      **AVATAR_FILL
    }

    args.outputs.borders << {
      x: x,
      y: y,
      w: self.class.box_width,
      h: self.class.box_height,
      **border_color
    }

    args.outputs.borders << {
      x: avatar_x,
      y: avatar_y,
      w: self.class.avatar_size,
      h: self.class.avatar_size,
      **border_color
    }

    render_placeholder_player_sprite(
      args,
      x: avatar_x,
      y: avatar_y,
      w: self.class.avatar_size,
      h: self.class.avatar_size,
      color: border_color
    )

    if meta_label
      args.outputs.labels << {
        x: x + self.class.box_width - 14,
        y: y + self.class.box_height - 16,
        text: meta_label,
        alignment_enum: 2,
        size_enum: meta_label_size_enum,
        **meta_label_color
      }
    end

    if meta_value
      args.outputs.labels << {
        x: x + self.class.box_width - 14,
        y: y + self.class.box_height - 38,
        text: meta_value,
        alignment_enum: 2,
        size_enum: meta_value_size_enum,
        **meta_value_color
      }
    end

    if secondary_meta_label
      args.outputs.labels << {
        x: x + self.class.box_width - 14,
        y: y + self.class.box_height - 66,
        text: secondary_meta_label,
        alignment_enum: 2,
        size_enum: secondary_meta_label_size_enum,
        **secondary_meta_label_color
      }
    end

    if secondary_meta_value
      args.outputs.labels << {
        x: x + self.class.box_width - 14,
        y: y + self.class.box_height - 88,
        text: secondary_meta_value,
        alignment_enum: 2,
        size_enum: secondary_meta_value_size_enum,
        **secondary_meta_value_color
      }
    end

    if tertiary_meta_label
      args.outputs.labels << {
        x: x + self.class.box_width - WIN_LABEL_RIGHT_MARGIN,
        y: y + self.class.box_height - WIN_ROW_Y_OFFSET,
        text: tertiary_meta_label,
        alignment_enum: 2,
        size_enum: tertiary_meta_label_size_enum,
        **tertiary_meta_label_color
      }
    end

    args.outputs.labels << {
      x: x + 14,
      y: title_y,
      text: title,
      alignment_enum: 0,
      size_enum: title_size_enum,
      **title_color
    }

    args.outputs.labels << {
      x: x + 14,
      y: subtitle_y,
      text: subtitle,
      alignment_enum: 0,
      size_enum: subtitle_size_enum,
      **subtitle_color
    }

    render_arrow(args, x: x, y: y, direction: arrow_direction, color: arrow_color) if arrow_direction
  end

  private

  def render_arrow(args, x:, y:, direction:, color:)
    direction_renderer.render(
      args,
      x: x + self.class.box_width - WIN_ARROW_RIGHT_MARGIN - WIN_ARROW_SIZE,
      y: y + self.class.box_height - WIN_ROW_Y_OFFSET - 21,
      size: WIN_ARROW_SIZE,
      direction: direction,
      color: color
    )
  end

  def direction_renderer
    @direction_renderer ||= DirectionRenderer.new
  end

  def render_placeholder_player_sprite(args, x:, y:, w:, h:, color:)
    line_count = 8
    thickness = 3
    step_x = ((w - thickness).to_f / (line_count - 1))
    step_y = ((h - thickness).to_f / (line_count - 1))

    line_count.times do |index|
      offset_x = (index * step_x).to_i
      offset_y = (index * step_y).to_i
      args.outputs.solids << {
        x: x + offset_x,
        y: y + offset_y,
        w: thickness,
        h: thickness,
        **color
      }
      args.outputs.solids << {
        x: x + w - thickness - offset_x,
        y: y + offset_y,
        w: thickness,
        h: thickness,
        **color
      }
    end
  end
end
