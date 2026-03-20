def test_wall_renderer_animates_undragged_wall_placement_from_reserve(args, assert)
  wall = WallRendererTestFakeWall.new
  renderer = WallRenderer.new(cell_size: 48, cell_gap: 6, board_pixel_size: 480)
  game = WallRendererTestFakeGame.new(wall)
  fake_args = WallRendererTestFakeArgs.new

  renderer.render_reserve_walls(fake_args, game, 100, 200)
  wall.placed = true
  fake_args.state.tick_count = 1
  fake_args.outputs.solids = []

  renderer.render_placed_walls(fake_args, game, 100, 200)

  solid = fake_args.outputs.solids[0]
  assert.equal! true, solid[:x] > 20, "Expected animated wall placement to move away from its reserve slot."
  assert.equal! true, solid[:x] < 100, "Expected animated wall placement to remain short of its board target on the next frame."
end

class WallRendererTestFakeWall
  attr_accessor :placed
  attr_reader :player, :color

  def initialize
    @placed = false
    @player = Object.new
    @color = [210, 165, 95]
  end

  def placed?
    @placed
  end

  def render(args, x, y, w, h)
    args.outputs.solids << { x: x, y: y, w: w, h: h }
  end

  def placed_rect(board_x, board_y, cell_width:, cell_height:, cell_gap:)
    { x: 100, y: 200, w: 90, h: 10 }
  end
end

class WallRendererTestFakeGame
  attr_reader :walls, :current_player

  def initialize(wall)
    @walls = [wall]
    @current_player = wall.player
    @reserve_rects = {
      wall => { x: 20, y: 40, w: 90, h: 10 }
    }
  end

  def reserve_wall_rects(args, board_x, board_y)
    @reserve_rects
  end
end

class WallRendererTestFakeOutputs
  attr_accessor :solids, :sprites, :borders

  def initialize
    @solids = []
    @sprites = []
    @borders = []
  end
end

class WallRendererTestFakeState
  attr_accessor :tick_count

  def initialize
    @tick_count = 0
  end
end

class WallRendererTestFakeArgs
  attr_reader :outputs, :state

  def initialize
    @outputs = WallRendererTestFakeOutputs.new
    @state = WallRendererTestFakeState.new
  end
end
