def test_wall_renderer_animates_undragged_wall_placement_from_reserve(args, assert)
  wall = WallRendererTestFakeWall.new
  renderer = WallRenderer.new(cell_size: 48, cell_gap: 6, board_pixel_size: 480)
  game = WallRendererTestFakeGame.new(wall)
  fake_args = WallRendererTestFakeArgs.new

  renderer.render_reserve_walls(fake_args, game, 100, 200)
  wall.placed = true
  fake_args.state.tick_count = 1
  renderer.render_placed_walls(fake_args, game, 100, 200)
  fake_args.state.tick_count = 2
  fake_args.outputs.sprites = []

  renderer.render_placed_walls(fake_args, game, 100, 200)

  sprite = fake_args.outputs.sprites[0]
  assert.equal! true, sprite[:x] > 20, "Expected animated wall placement to move away from its reserve slot."
  assert.equal! true, sprite[:x] < 60, "Expected animated wall placement to remain short of its board target on the next frame."
  assert.equal! true, sprite[:angle] > 0, "Expected animated wall placement to rotate toward the board orientation."
end

def test_wall_renderer_dragged_preview_uses_render_target_sprite_rotation(args, assert)
  wall = WallRendererTestFakeWall.new
  renderer = WallRenderer.new(cell_size: 48, cell_gap: 6, board_pixel_size: 480)
  game = WallRendererTestFakeGame.new(wall)
  fake_args = WallRendererTestFakeArgs.new

  renderer.render_reserve_walls(
    fake_args,
    game,
    100,
    200,
    {
      dragged_wall: wall,
      dragged_rect: { x: 40, y: 80, w: 90, h: 10 },
      dragged_angle: 45,
      hover_wall: nil
    }
  )

  assert.equal! 0, fake_args.outputs.solids.length, "Expected dragged rotated wall preview to avoid solid rendering."
  assert.equal! 1, fake_args.outputs.sprites.length, "Expected dragged rotated wall preview to render as a sprite."
  sprite = fake_args.outputs.sprites[0]
  assert.equal! 45, sprite[:angle], "Expected dragged rotated wall preview sprite to carry the requested angle."
  assert.equal! "wall_sprite_#{wall.object_id}", sprite[:path], "Expected dragged rotated wall preview to use the wall render target."
end

class WallRendererTestFakeWall
  attr_accessor :placed
  attr_reader :player, :color, :width, :height

  def initialize
    @placed = false
    @player = Object.new
    @color = [210, 165, 95]
    @width = 90
    @height = 10
  end

  def placed?
    @placed
  end

  def render(args, x, y, w, h, color_override = color)
    args.outputs.solids << { x: x, y: y, w: w, h: h }
  end

  def placed_rect(board_x, board_y, cell_width, cell_height, cell_gap)
    { x: 100, y: 200, w: 10, h: 90 }
  end
end

class WallRendererTestFakeGame
  attr_reader :walls, :current_player, :players

  def initialize(wall)
    @walls = [wall]
    @current_player = wall.player
    @players = [wall.player]
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
    @render_targets = {}
  end

  def [](key)
    @render_targets[key] ||= WallRendererTestFakeRenderTarget.new
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

class WallRendererTestFakeRenderTarget
  attr_accessor :w, :h, :background_color, :clear_before_render, :solids, :labels

  def initialize
    @solids = []
    @labels = []
  end
end
