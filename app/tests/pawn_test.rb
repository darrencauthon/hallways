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
  assert.equal! "sprites/pawn_white.png", sprite[:path], "Expected light pawn to use white pawn sprite."
end

def test_pawn_render_uses_black_sprite_for_dark_pawn(args, assert)
  pawn = Pawn.new(2, 4, [50, 50, 50], player: PawnTestFakePlayer.new("Tester"), cell_width: 48, cell_height: 48)
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 6)

  sprite = fake_args.outputs.sprites[0]
  assert.equal! "sprites/pawn_black.png", sprite[:path], "Expected dark pawn to use black pawn sprite."
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
  attr_reader :outputs

  def initialize
    @outputs = PawnTestFakeOutputs.new
  end
end

class PawnTestFakePlayer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end
