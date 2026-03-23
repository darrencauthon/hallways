def test_pawn_stores_grid_position(args, assert)
  pawn = Pawn.new(3, 5, [100, 110, 120], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)

  assert.equal! 3, pawn.col, "Expected pawn column to be stored."
  assert.equal! 5, pawn.row, "Expected pawn row to be stored."
end

def test_pawn_render_outputs_one_sprite(args, assert)
  pawn = Pawn.new(2, 4, [245, 245, 245], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 6)

  assert.equal! 1, fake_args.outputs.sprites.length, "Expected one pawn sprite output."
end

def test_pawn_render_places_pawn_in_expected_cell(args, assert)
  pawn = Pawn.new(2, 4, [245, 245, 245], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 6)

  sprite = fake_args.outputs.sprites[0]
  assert.equal! 218, sprite[:x], "Expected pawn x to be centered in target cell."
  assert.equal! 426, sprite[:y], "Expected pawn y to be centered in target cell."
  assert.equal! 28, sprite[:w], "Expected pawn width to be 28."
  assert.equal! 28, sprite[:h], "Expected pawn height to be 28."
  assert.equal! "sprites/solid-circle.png", sprite[:path], "Expected pawn to use solid circle sprite."
  assert.equal! 245, sprite[:r], "Expected pawn sprite tint to use pawn red channel."
  assert.equal! 245, sprite[:g], "Expected pawn sprite tint to use pawn green channel."
  assert.equal! 245, sprite[:b], "Expected pawn sprite tint to use pawn blue channel."
  assert.equal! 255, sprite[:a], "Expected pawn sprite alpha to be fully opaque."
end

def test_pawn_render_tints_circle_for_pawn_color(args, assert)
  pawn = Pawn.new(2, 4, [50, 60, 70], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 6)

  sprite = fake_args.outputs.sprites[0]
  assert.equal! "sprites/solid-circle.png", sprite[:path], "Expected pawn to use solid circle sprite."
  assert.equal! 50, sprite[:r], "Expected pawn sprite tint to use pawn red channel."
  assert.equal! 60, sprite[:g], "Expected pawn sprite tint to use pawn green channel."
  assert.equal! 70, sprite[:b], "Expected pawn sprite tint to use pawn blue channel."
end

def test_pawn_renderer_animates_undragged_move_between_cells(args, assert)
  pawn = Pawn.new(4, 0, [245, 245, 245], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)
  renderer = PawnRenderer.new(cell_size: 48, cell_gap: 6)
  game = PawnRendererTestFakeGame.new([pawn])
  fake_args = PawnTestFakeArgs.new

  renderer.render(fake_args, game, 100, 200, dragged_pawn: nil, dragged_pawn_x: 0, dragged_pawn_y: 0)
  pawn.move_to(4, 1)
  fake_args.state.tick_count = 1
  renderer.render(fake_args, game, 100, 200, dragged_pawn: nil, dragged_pawn_x: 0, dragged_pawn_y: 0)
  fake_args.state.tick_count = 2
  fake_args.outputs.sprites = []

  renderer.render(fake_args, game, 100, 200, dragged_pawn: nil, dragged_pawn_x: 0, dragged_pawn_y: 0)

  sprite = fake_args.outputs.sprites[0]
  assert.equal! true, sprite[:y] > 210, "Expected animated pawn move to advance past the original square."
  assert.equal! true, sprite[:y] < 264, "Expected animated pawn move to remain short of the destination square on the next frame."
end

def test_pawn_renderer_renders_available_move_highlights_in_player_color(args, assert)
  renderer = PawnRenderer.new(cell_size: 48, cell_gap: 6)
  fake_args = PawnTestFakeArgs.new
  squares = [PawnTestFakeSquare.new(4, 1), PawnTestFakeSquare.new(3, 0), PawnTestFakeSquare.new(5, 0)]

  renderer.render_available_moves(fake_args, 100, 200, squares, [143, 45, 45])

  assert.equal! 12, fake_args.outputs.solids.length, "Expected four edge strips per legal move square for a 3px outline."
  first = fake_args.outputs.solids[0]
  assert.equal! 143, first[:r], "Expected available move highlight red channel to match player color."
  assert.equal! 45, first[:g], "Expected available move highlight green channel to match player color."
  assert.equal! 45, first[:b], "Expected available move highlight blue channel to match player color."
  assert.equal! 3, first[:h], "Expected highlight stroke thickness to be 3 pixels."
end

class PawnTestFakeOutputs
  attr_accessor :sprites, :solids, :borders

  def initialize
    @sprites = []
    @solids = []
    @borders = []
  end
end

class PawnTestFakeArgs
  attr_reader :outputs, :state

  def initialize
    @outputs = PawnTestFakeOutputs.new
    @state = PawnTestFakeState.new
  end
end

class PawnTestFakeState
  attr_accessor :tick_count

  def initialize
    @tick_count = 0
  end
end

class PawnRendererTestFakeGame
  attr_reader :pawns

  def initialize(pawns)
    @pawns = pawns
  end
end

class PawnTestFakePlayer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class PawnTestFakeSquare
  attr_reader :col, :row

  def initialize(col, row)
    @col = col
    @row = row
  end
end
