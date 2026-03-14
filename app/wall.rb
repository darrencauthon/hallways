class Wall
  attr_reader :lane, :slot, :width, :height, :color, :player, :wall_well

  def initialize(lane:, slot:, width:, height:, color:, player:)
    @lane = lane
    @slot = slot
    @width = width
    @height = height
    @color = color
    @player = player
  end

  def render(args, x, y)
    args.outputs.solids << {
      x: x,
      y: y,
      w: width,
      h: height,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  def placed?
    !wall_well.nil?
  end

  def assign_to_wall_well(wall_well)
    @wall_well = wall_well
  end
end
