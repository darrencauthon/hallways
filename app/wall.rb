class Wall
  attr_reader :lane, :slot, :width, :height, :color, :player

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
end
