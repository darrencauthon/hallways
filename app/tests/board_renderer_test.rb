def test_board_renderer_highlights_current_player_goal_row(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  renderer = BoardRenderer.new(cell_size: 48, cell_gap: 6, board_pixel_size: 480)
  fake_args = BoardRendererTestFakeArgs.new

  renderer.render(fake_args, game, 100, 120)

  goal_square = fake_args.outputs.solids.find { |solid| solid[:x] == 100 && solid[:y] == 120 + (8 * 54) }
  assert.equal! 143, goal_square[:r], "Expected current player's goal row to use the player's red channel."
  assert.equal! 45, goal_square[:g], "Expected current player's goal row to use the player's green channel."
  assert.equal! 45, goal_square[:b], "Expected current player's goal row to use the player's blue channel."
end

def test_board_renderer_leaves_non_goal_square_default_color(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  renderer = BoardRenderer.new(cell_size: 48, cell_gap: 6, board_pixel_size: 480)
  fake_args = BoardRendererTestFakeArgs.new

  renderer.render(fake_args, game, 100, 120)

  square = fake_args.outputs.solids.find { |solid| solid[:x] == 100 && solid[:y] == 120 }
  assert.equal! 0, square[:r], "Expected non-goal square red channel to remain default."
  assert.equal! 0, square[:g], "Expected non-goal square green channel to remain default."
  assert.equal! 0, square[:b], "Expected non-goal square blue channel to remain default."
end

class BoardRendererTestFakeOutputs
  attr_accessor :sprites, :solids, :borders

  def initialize
    @sprites = []
    @solids = []
    @borders = []
  end
end

class BoardRendererTestFakeArgs
  attr_reader :outputs

  def initialize
    @outputs = BoardRendererTestFakeOutputs.new
  end
end
