def test_pawn_stores_grid_position(args, assert)
  pawn = Pawn.new(3, 5, [100, 110, 120])

  assert.equal! 3, pawn.col, "Expected pawn column to be stored."
  assert.equal! 5, pawn.row, "Expected pawn row to be stored."
end

def test_pawn_render_outputs_one_solid_and_one_border(args, assert)
  pawn = Pawn.new(2, 4, [100, 110, 120])
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 48, 6)

  assert.equal! 1, fake_args.outputs.solids.length, "Expected one solid output."
  assert.equal! 1, fake_args.outputs.borders.length, "Expected one border output."
end

def test_pawn_render_places_pawn_in_expected_cell(args, assert)
  pawn = Pawn.new(2, 4, [100, 110, 120])
  fake_args = PawnTestFakeArgs.new

  pawn.render(fake_args, 100, 200, 48, 6)

  solid = fake_args.outputs.solids[0]
  assert.equal! 218, solid[:x], "Expected pawn x to be centered in target cell."
  assert.equal! 426, solid[:y], "Expected pawn y to be centered in target cell."
  assert.equal! 28, solid[:w], "Expected pawn width to be 28."
  assert.equal! 28, solid[:h], "Expected pawn height to be 28."
  assert.equal! 100, solid[:r], "Expected pawn red color channel to match."
  assert.equal! 110, solid[:g], "Expected pawn green color channel to match."
  assert.equal! 120, solid[:b], "Expected pawn blue color channel to match."
end

class PawnTestFakeOutputs
  attr_accessor :solids, :borders

  def initialize
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
