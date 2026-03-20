class Wall
  attr_reader :lane, :slot, :width, :height, :color, :player, :wall_wells

  def initialize(lane:, slot:, width:, height:, color:, player:)
    @lane = lane
    @slot = slot
    @width = width
    @height = height
    @color = color
    @player = player
  end

  def render_on_board(args, board_x, board_y, cell_width:, cell_height:, cell_gap:)
    rect = placed_rect(board_x, board_y, cell_width, cell_height, cell_gap)
    return if rect.nil?

    render(args, rect[:x], rect[:y], rect[:w], rect[:h])
  end

  def render(args, x, y, width_override = width, height_override = height)
    args.outputs.solids << {
      x: x,
      y: y,
      w: width_override,
      h: height_override,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  def wall_well
    wall_wells&.first
  end

  def placed?
    !wall_well.nil?
  end

  def assign_to_wall_wells(wall_wells)
    @wall_wells = wall_wells
  end

  def placed_rect(board_x, board_y, cell_width, cell_height, cell_gap)
    return nil unless placed?

    first_rect = wall_wells[0].rect(
      board_x,
      board_y,
      cell_width: cell_width,
      cell_height: cell_height,
      cell_gap: cell_gap
    )
    second_rect = wall_wells[1].rect(
      board_x,
      board_y,
      cell_width: cell_width,
      cell_height: cell_height,
      cell_gap: cell_gap
    )

    if wall_well.orientation == :horizontal
      {
        x: first_rect[:x],
        y: first_rect[:y],
        w: (second_rect[:x] + second_rect[:w]) - first_rect[:x],
        h: first_rect[:h]
      }
    else
      {
        x: first_rect[:x],
        y: first_rect[:y],
        w: first_rect[:w],
        h: (second_rect[:y] + second_rect[:h]) - first_rect[:y]
      }
    end
  end
end
