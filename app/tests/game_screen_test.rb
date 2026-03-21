require "app/screens/game_screen.rb"

def test_game_screen_escape_returns_to_main_menu(args, assert)
  screen = GameScreen.new

  action = screen.tick(TitleScreenTestHelpers.build_fake_args(escape: true))

  assert.equal! :main_menu, action, "Expected Escape during a game to return to the main menu."
end

def test_game_screen_skips_controller_actions_while_pawn_animation_in_progress(args, assert)
  screen = GameScreen.new
  controller = GameScreenTestFakeController.new
  fake_game = GameScreenTestFakeGame.new(controller)
  fake_args = GameScreenTestHelpers.build_fake_args_with_grid(tick_count: 10)

  screen.define_singleton_method(:game) { fake_game }
  screen.send(:start_pawn_move_animation, fake_args)

  screen.tick(fake_args)

  assert.equal! 0, controller.calls, "Expected controller actions to be blocked while pawn animation is playing."
end

def test_game_screen_skips_controller_actions_while_wall_animation_in_progress(args, assert)
  screen = GameScreen.new
  controller = GameScreenTestFakeController.new
  fake_game = GameScreenTestFakeGame.new(controller)
  fake_args = GameScreenTestHelpers.build_fake_args_with_grid(tick_count: 10)

  screen.define_singleton_method(:game) { fake_game }
  screen.send(:start_wall_place_animation, fake_args)

  screen.tick(fake_args)

  assert.equal! 0, controller.calls, "Expected controller actions to be blocked while wall animation is playing."
end

def test_game_screen_keeps_last_wall_placement_active_across_wall_span_gap(args, assert)
  screen = GameScreen.new
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  board_x = 100
  board_y = 120
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0 }
  wall_span = game.board.wall_span_from(wall_well, preferred_side: :positive)
  left_rect = wall_span[0].rect(board_x, board_y, cell_width: 48, cell_height: 48, cell_gap: 6)
  right_rect = wall_span[1].rect(board_x, board_y, cell_width: 48, cell_height: 48, cell_gap: 6)
  gap_x = left_rect[:x] + left_rect[:w] + ((right_rect[:x] - (left_rect[:x] + left_rect[:w])) / 2)
  gap_y = left_rect[:y] + (left_rect[:h] / 2)
  fake_args = GameScreenTestHelpers.build_fake_args_for_drag(mouse_x: gap_x, mouse_y: gap_y)

  screen.define_singleton_method(:game) { game }
  screen.instance_variable_set(:@dragged_wall, wall)
  screen.instance_variable_set(:@last_hovered_wall_placement, { wall_well: wall_well, preferred_side: :positive, wall_span: wall_span })

  placement = screen.send(:hovered_available_wall_placement, fake_args, board_x, board_y)

  assert.equal! wall_well, placement[:wall_well], "Expected wall placement to stay active while dragging across the gap between wall wells."
end

def test_game_screen_clears_last_wall_placement_when_mouse_moves_into_square(args, assert)
  screen = GameScreen.new
  game = Game.new(cell_width: 48, cell_height: 48)
  wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  board_x = 100
  board_y = 120
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0 }
  wall_span = game.board.wall_span_from(wall_well, preferred_side: :positive)
  fake_args = GameScreenTestHelpers.build_fake_args_for_drag(mouse_x: 100 + (4 * 54) + 24, mouse_y: 120 + 24)

  screen.define_singleton_method(:game) { game }
  screen.instance_variable_set(:@dragged_wall, wall)
  screen.instance_variable_set(:@last_hovered_wall_placement, { wall_well: wall_well, preferred_side: :positive, wall_span: wall_span })

  placement = screen.send(:hovered_available_wall_placement, fake_args, board_x, board_y)

  assert.equal! nil, placement, "Expected wall placement to clear when dragging off the wall track and into a square."
end

def test_game_screen_clicking_legal_square_moves_current_pawn_with_animation(args, assert)
  screen = GameScreen.new
  game = Game.new(cell_width: 48, cell_height: 48)
  fake_args = GameScreenTestHelpers.build_fake_args_with_grid(tick_count: 10, mouse_x: 640, mouse_y: 198, mouse_down: true)

  screen.define_singleton_method(:game) { game }
  screen.tick(fake_args)

  pawn = game.pawns[0]
  assert.equal! 4, pawn.col, "Expected click-to-move to keep the current pawn in the same column for a straight move."
  assert.equal! 1, pawn.row, "Expected click-to-move to move the pawn to the hovered legal square."
  assert.equal! true, screen.send(:pawn_move_animation_in_progress?, fake_args), "Expected click-to-move to trigger the standard pawn move animation."
end

def test_game_screen_clicking_legal_wall_well_places_wall_with_animation(args, assert)
  screen = GameScreen.new
  game = Game.new(cell_width: 48, cell_height: 48)
  board_x = (1280 - ((9 * 48) + (8 * 6))) / 2
  board_y = 120
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0 }
  rect = wall_well.rect(board_x, board_y, cell_width: 48, cell_height: 48, cell_gap: 6)
  fake_args = GameScreenTestHelpers.build_fake_args_with_grid(
    tick_count: 10,
    mouse_x: rect[:x] + (rect[:w] / 2),
    mouse_y: rect[:y] + (rect[:h] / 2),
    mouse_down: true
  )

  screen.define_singleton_method(:game) { game }
  screen.tick(fake_args)

  assert.equal! false, wall_well.wall.nil?, "Expected click-to-place to assign a wall to the hovered wall well."
  assert.equal! true, screen.send(:wall_place_animation_in_progress?, fake_args), "Expected click-to-place to trigger the standard wall placement animation."
end

def test_game_screen_clicking_between_wall_wells_uses_last_hovered_wall_placement(args, assert)
  screen = GameScreen.new
  game = Game.new(cell_width: 48, cell_height: 48)
  board_x = (1280 - ((9 * 48) + (8 * 6))) / 2
  board_y = 120
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0 }
  wall_span = game.board.wall_span_from(wall_well, preferred_side: :positive)
  left_rect = wall_span[0].rect(board_x, board_y, cell_width: 48, cell_height: 48, cell_gap: 6)
  right_rect = wall_span[1].rect(board_x, board_y, cell_width: 48, cell_height: 48, cell_gap: 6)
  gap_x = left_rect[:x] + left_rect[:w] + ((right_rect[:x] - (left_rect[:x] + left_rect[:w])) / 2)
  gap_y = left_rect[:y] + (left_rect[:h] / 2)

  screen.define_singleton_method(:game) { game }

  hover_args = GameScreenTestHelpers.build_fake_args_with_grid(
    tick_count: 10,
    mouse_x: left_rect[:x] + (left_rect[:w] / 2),
    mouse_y: left_rect[:y] + (left_rect[:h] / 2)
  )
  click_args = GameScreenTestHelpers.build_fake_args_with_grid(
    tick_count: 11,
    mouse_x: gap_x,
    mouse_y: gap_y,
    mouse_down: true
  )

  screen.tick(hover_args)
  screen.tick(click_args)

  assert.equal! false, wall_well.wall.nil?, "Expected click-to-place to keep the last wall placement active across the gap between wall wells."
  assert.equal! true, screen.send(:wall_place_animation_in_progress?, click_args), "Expected gap click-to-place to trigger the standard wall placement animation."
end

module GameScreenTestHelpers
  def self.build_fake_args_with_grid(tick_count:, mouse_x: nil, mouse_y: nil, mouse_down: false, mouse_up: false)
    key_down = FakeKeyDown.new(false, false, false, false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    mouse = FakeMouse.new(mouse_x, mouse_y, mouse_down, mouse_up)
    inputs = FakeInputs.new(keyboard, mouse)
    outputs = GameScreenTestFakeOutputs.new
    state = GameScreenTestFakeState.new(tick_count)
    grid = GameScreenTestFakeGrid.new

    GameScreenTestFakeArgs.new(inputs, outputs, state, grid)
  end

  def self.build_fake_args_for_drag(mouse_x:, mouse_y:)
    key_down = FakeKeyDown.new(false, false, false, false, false, false)
    keyboard = FakeKeyboard.new(key_down)
    mouse = FakeMouse.new(mouse_x, mouse_y, false, false)
    inputs = FakeInputs.new(keyboard, mouse)
    outputs = GameScreenTestFakeOutputs.new
    state = GameScreenTestFakeState.new(0)
    grid = GameScreenTestFakeGrid.new

    GameScreenTestFakeArgs.new(inputs, outputs, state, grid)
  end
end

class GameScreenTestFakeController
  attr_reader :calls

  def initialize
    @calls = 0
  end

  def next_action(args:, game:)
    @calls += 1
    { type: :thinking }
  end
end

class GameScreenTestFakePlayer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class GameScreenTestFakeGame
  attr_reader :winner, :current_player

  def initialize(controller)
    @controller = controller
    @winner = nil
    @current_player = GameScreenTestFakePlayer.new("Bot 1")
  end

  def current_controller
    @controller
  end

  def sync_render_state(dragged_wall:, dragged_pawn:, dragged_pawn_offset_x:, dragged_pawn_offset_y:)
  end

  def render(args, board_x:, board_y:, wall_drop_target:, pawn_drop_target:, pawn_origin_highlight: nil)
  end
end

class GameScreenTestFakeGrid
  attr_reader :w

  def initialize
    @w = 1280
  end
end

class GameScreenTestFakeState
  attr_accessor :tick_count

  def initialize(tick_count)
    @tick_count = tick_count
  end
end

class GameScreenTestFakeOutputs
  attr_accessor :background_color, :labels, :sprites, :solids, :borders

  def initialize
    @labels = []
    @sprites = []
    @solids = []
    @borders = []
    @render_targets = {}
  end

  def [](key)
    @render_targets[key] ||= WallRendererTestFakeRenderTarget.new
  end
end

class GameScreenTestFakeArgs
  attr_reader :inputs, :outputs, :state, :grid

  def initialize(inputs, outputs, state, grid)
    @inputs = inputs
    @outputs = outputs
    @state = state
    @grid = grid
  end
end
