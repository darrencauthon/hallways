require "app/models/pawn.rb"
require "app/models/board.rb"
require "app/models/path_distance_calculator.rb"
require "app/models/pawn_move_finder.rb"
require "app/models/player_palette.rb"
require "app/models/wall_placement_rules.rb"
require "app/models/wall.rb"
require "app/models/player.rb"
require "app/controllers/null_controller.rb"
require "app/controllers/bot_controller.rb"
require "app/controllers/human_controller.rb"
require "app/controllers/random_bot_controller.rb"
require "app/controllers/caveman_bot_controller.rb"
require "app/controllers/path_bot_controller.rb"
require "app/controllers/last_line_bot_controller.rb"
require "app/controllers/pressure_bot_controller.rb"
require "app/renderers/game_renderer.rb"

class Game
  WALLS_PER_LANE = 10
  WALLS_PER_PLAYER_TWO = 10
  WALLS_PER_PLAYER_FOUR = 5
  WALL_COLOR = [210, 165, 95]
  WALL_WIDTH = 90
  WALL_HEIGHT = 10
  attr_reader :pawns, :board, :walls, :players, :winner, :cell_gap, :mode, :player_types, :player_count

  def initialize(cell_width:, cell_height:, cell_gap: 6, mode: :human_vs_human, player_types: nil, player_count: nil)
    @mode = mode
    @player_count = player_count || (player_types&.length || 2)
    @player_types = player_types || default_player_types_for_count(@player_count)
    @player_count = @player_types.length
    @cell_gap = cell_gap
    @board = Board.new(cell_width: cell_width, cell_height: cell_height)
    @players = build_players
    @pawns = build_pawns(cell_width: cell_width, cell_height: cell_height)
    @walls = build_walls
    @turn_index = 0
    @away_distances = {}
    recompute_away_distances!
  end

  def current_player
    players[@turn_index]
  end

  def current_controller
    current_player.controller
  end

  def away_distance_for(player)
    @away_distances[player]
  end

  def next_turn!
    @turn_index = (@turn_index + 1) % players.length
  end

  def can_move_pawn_to?(pawn, col, row)
    return false unless winner.nil?
    return false if pawn.nil?
    return false unless pawn.player == current_player
    return false unless board.square_at(col, row)
    return false unless pawn_move_finder.moves_for(game: self, pawn: pawn).any? { |move| move[:col] == col && move[:row] == row }

    true
  end

  def move_pawn_to(pawn, col, row)
    return false unless can_move_pawn_to?(pawn, col, row)

    pawn.move_to(col, row)
    recompute_away_distances!
    @winner = pawn.player if pawn.player.goal_reached?(col, row)
    next_turn! if winner.nil?
    true
  end

  def can_place_wall_in_well?(wall, wall_well, preferred_side: :positive)
    wall_placement_rules.can_place?(
      game: self,
      wall: wall,
      wall_well: wall_well,
      preferred_side: preferred_side
    )
  end

  def place_wall_in_well(wall, wall_well)
    place_wall_in_well_with_side(wall, wall_well, preferred_side: :positive)
  end

  def place_wall_in_well_with_side(wall, wall_well, preferred_side:)
    return false unless can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

    wall_span = wall_placement_rules.wall_span_for(game: self, wall_well: wall_well, preferred_side: preferred_side)
    wall.assign_to_wall_wells(wall_span)
    wall_span.each { |occupied_well| occupied_well.assign_wall(wall) }
    recompute_away_distances!
    next_turn!
    true
  end

  def sync_render_state(dragged_wall:, dragged_pawn:, dragged_pawn_offset_x:, dragged_pawn_offset_y:)
    @dragged_wall = dragged_wall
    @dragged_pawn = dragged_pawn
    @dragged_pawn_offset_x = dragged_pawn_offset_x
    @dragged_pawn_offset_y = dragged_pawn_offset_y
    @dragged_wall_orientation = nil if dragged_wall.nil?
  end

  def reserve_wall_rects(args, board_x, board_y)
    game_renderer.reserve_wall_rects(args, game: self, board_x: board_x, board_y: board_y)
  end

  def render(
    args,
    board_x:,
    board_y:,
    wall_drop_target:,
    pawn_drop_target:,
    pawn_origin_highlight:,
    available_pawn_moves:
  )
    renderer = game_renderer
    dragged_wall_preview = renderer.dragged_wall_rect(
      args,
      game: self,
      board_x: board_x,
      board_y: board_y,
      dragged_wall: @dragged_wall,
      dragged_wall_orientation: @dragged_wall_orientation
    )
    @dragged_wall_orientation = dragged_wall_preview[:orientation]

    renderer.render(
      args,
      game: self,
      board_x: board_x,
      board_y: board_y,
      wall_drop_target: wall_drop_target,
      pawn_drop_target: pawn_drop_target,
      pawn_origin_highlight: pawn_origin_highlight,
      available_pawn_moves: available_pawn_moves,
      dragged_wall: @dragged_wall,
      dragged_rect: dragged_wall_preview[:rect],
      dragged_angle: dragged_wall_preview[:angle],
      hover_wall: renderer.hovered_reserve_wall(args, game: self, board_x: board_x, board_y: board_y),
      dragged_pawn: @dragged_pawn,
      dragged_pawn_x: dragged_pawn_x(args),
      dragged_pawn_y: dragged_pawn_y(args)
    )
  end

  private

  def default_player_types_for_count(player_count)
    return [:human, :human, :human, :human] if player_count == 4

    player_types_for_mode(mode)
  end

  def player_types_for_mode(mode)
    return [:human, :random_bot] if mode == :human_vs_computer

    [:human, :human]
  end

  def build_player(index:, winning_row:, winning_col: nil)
    player_type = player_types[index]
    Player.new(
      display_name_for(index, player_type),
      game: self,
      winning_row: winning_row,
      winning_col: winning_col,
      controller: controller_for(player_type),
      image: player_image_for(player_type)
    )
  end

  def display_name_for(index, player_type)
    return "Player #{index + 1}" unless bot_player_type?(player_type)

    bot_display_name_for(player_type)
  end

  def bot_display_name_for(player_type)
    return "Caveman" if player_type == :caveman_bot
    return "PathBot" if player_type == :path_bot
    return "Runner" if player_type == :last_line_bot
    return "Cowboy" if player_type == :pressure_bot

    "RandomBot"
  end

  def controller_for(player_type)
    return PathBotController.new if player_type == :path_bot
    return LastLineBotController.new if player_type == :last_line_bot
    return PressureBotController.new if player_type == :pressure_bot
    return CavemanBotController.new if player_type == :caveman_bot
    return RandomBotController.new if bot_player_type?(player_type)

    HumanController.new
  end

  def bot_player_type?(player_type)
    player_type == :random_bot || player_type == :caveman_bot || player_type == :computer || player_type == :path_bot || player_type == :last_line_bot || player_type == :pressure_bot
  end

  def game_renderer
    if @game_renderer.nil? || @game_renderer.cell_gap != cell_gap
      @game_renderer = GameRenderer.new(cell_gap: cell_gap)
    end

    @game_renderer
  end

  def player_image_for(player_type)
    return "sprites/caveman.png" if player_type == :caveman_bot
    return "sprites/runner.png" if player_type == :last_line_bot
    return "sprites/cowboy.png" if player_type == :pressure_bot

    nil
  end

  def dragged_pawn_x(args)
    mouse_x(args) - (@dragged_pawn_offset_x || 0)
  end

  def dragged_pawn_y(args)
    mouse_y(args) - (@dragged_pawn_offset_y || 0)
  end

  def mouse_x(args)
    args.inputs.mouse.x || 0
  end

  def mouse_y(args)
    args.inputs.mouse.y || 0
  end

  def build_walls
    walls = []
    walls_per_player = player_count == 4 ? WALLS_PER_PLAYER_FOUR : WALLS_PER_PLAYER_TWO

    players.each_with_index do |player, index|
      lane = wall_lane_for_player(index)
      slot_offset = wall_slot_offset_for_player(index)
      walls_per_player.times do |slot|
        walls << Wall.new(
          lane: lane,
          slot: slot_offset + slot,
          width: WALL_WIDTH,
          height: WALL_HEIGHT,
          color: WALL_COLOR,
          player: player
        )
      end
    end

    walls
  end

  def wall_lane_for_player(index)
    return :bottom if index == 0 || index == 2

    :top
  end

  def wall_slot_offset_for_player(index)
    return 0 unless player_count == 4
    return 5 if index == 2 || index == 3

    0
  end

  def build_players
    configs = player_start_configs
    configs.each_with_index.map do |config, index|
      build_player(index: index, winning_row: config[:winning_row], winning_col: config[:winning_col])
    end
  end

  def build_pawns(cell_width:, cell_height:)
    configs = player_start_configs
    configs.each_with_index.map do |config, index|
      color = pawn_color_for(index)
      Pawn.new(
        config[:start_col],
        config[:start_row],
        color,
        player: @players[index],
        cell_width: cell_width,
        cell_height: cell_height
      )
    end
  end

  def pawn_color_for(index)
    PlayerPalette::COLORS[index] || PlayerPalette::COLORS[0]
  end

  def player_start_configs
    if player_count == 4
      [
        { start_col: 4, start_row: 0, winning_row: 8, winning_col: nil },
        { start_col: 4, start_row: 8, winning_row: 0, winning_col: nil },
        { start_col: 0, start_row: 4, winning_row: nil, winning_col: 8 },
        { start_col: 8, start_row: 4, winning_row: nil, winning_col: 0 }
      ]
    else
      [
        { start_col: 4, start_row: 0, winning_row: 8, winning_col: nil },
        { start_col: 4, start_row: 8, winning_row: 0, winning_col: nil }
      ]
    end
  end

  def recompute_away_distances!
    @away_distances = players.each_with_object({}) do |player, distances|
      pawn = pawns.find { |candidate| candidate.player == player }
      distances[player] = if pawn.nil?
                            nil
                          else
                            path_distance_calculator.shortest_distance_to_goal(
                              board: board,
                              start_col: pawn.col,
                              start_row: pawn.row,
                              player: player,
                              extra_occupied_wall_wells: nil
                            )
                          end
    end
  end

  def path_distance_calculator
    @path_distance_calculator ||= PathDistanceCalculator.new
  end

  def pawn_move_finder
    @pawn_move_finder ||= PawnMoveFinder.new
  end

  def wall_placement_rules
    @wall_placement_rules ||= WallPlacementRules.new
  end
end
