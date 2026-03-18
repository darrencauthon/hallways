class GameScreenRenderer
  def render_background(args)
    args.outputs.background_color = [10, 10, 12]
  end

  def render_thinking_indicator(args, board_x:, board_y:, board_pixel_size:, current_player_name:)
    dot_count = ((args.state.tick_count || 0) / 20) % 4
    dots = "." * dot_count
    label = "#{current_player_name} thinking#{dots}"

    args.outputs.labels << {
      x: board_x + (board_pixel_size / 2),
      y: board_y + board_pixel_size + 108,
      text: label,
      alignment_enum: 1,
      size_enum: 2,
      r: 255,
      g: 215,
      b: 120
    }
  end
end
