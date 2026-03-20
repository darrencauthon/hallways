require "app/renderers/game_screen_renderer.rb"

class GameScreen
  attr_reader :board_size, :cell_size, :cell_gap, :board_y

  def initialize(board_size: 9, cell_size: 48, cell_gap: 6, board_y: 120, mode: :human_vs_human, player_count: nil, player_types: nil)
    @board_size = board_size
    @cell_size = cell_size
    @cell_gap = cell_gap
    @board_y = board_y
    @mode = mode
    @player_count = player_count
    @player_types = player_types
  end

  def tick(args)
    return :main_menu if menu_pressed?(args)

    game_screen_renderer.render_background(args)

    board_x = ((args.grid.w - board_pixel_size) / 2).to_i

    @computer_thinking = false
    if move_animation_in_progress?(args)
      @dragged_wall = nil
      clear_dragged_pawn
    else
      apply_current_controller_action(args)
      if human_turn?
        update_wall_drag_state(args, board_x, board_y)
        update_pawn_drag_state(args, board_x, board_y)
      else
        @dragged_wall = nil
        clear_dragged_pawn
      end
    end
    clickable_wall_target = available_click_wall_placement(args, board_x, board_y)
    wall_drop_target = hovered_available_wall_placement(args, board_x, board_y) if dragged_wall
    wall_drop_target ||= clickable_wall_target
    clickable_pawn_target = available_click_move_target(args, board_x, board_y)
    pawn_drop_target = available_pawn_drop_target(args, board_x, board_y) || clickable_pawn_target
    pawn_origin_highlight = clickable_pawn_origin_square(args, board_x, board_y, clickable_pawn_target)
    game.sync_render_state(
      dragged_wall: dragged_wall,
      dragged_pawn: dragged_pawn,
      dragged_pawn_offset_x: dragged_pawn_offset_x,
      dragged_pawn_offset_y: dragged_pawn_offset_y
    )

    game.render(
      args,
      board_x: board_x,
      board_y: board_y,
      wall_drop_target: wall_drop_target,
      pawn_drop_target: pawn_drop_target,
      pawn_origin_highlight: pawn_origin_highlight
    )
    if @computer_thinking
      game_screen_renderer.render_thinking_indicator(
        args,
        board_x: board_x,
        board_y: board_y,
        board_pixel_size: board_pixel_size,
        current_player_name: game.current_player.name
      )
    end

    return [:victory, game.winner.name] if game.winner
  end

  private

  def apply_current_controller_action(args)
    action = game.current_controller.next_action(args: args, game: game)
    return if action.nil?

    if action[:type] == :thinking
      @computer_thinking = true
    elsif action[:type] == :move_pawn
      moved = game.move_pawn_to(action[:pawn], action[:col], action[:row])
      start_pawn_move_animation(args) if moved
      @computer_thinking = false
    elsif action[:type] == :place_wall
      placed = game.place_wall_in_well_with_side(
        action[:wall],
        action[:wall_well],
        preferred_side: action[:preferred_side]
      )
      start_wall_place_animation(args) if placed
      @computer_thinking = false
    end
  end

  def update_wall_drag_state(args, board_x, board_y)
    if mouse_released?(args)
      if dragged_wall
        placement = hovered_available_wall_placement(args, board_x, board_y)
        if placement
          placed = game.place_wall_in_well_with_side(
            dragged_wall,
            placement[:wall_well],
            preferred_side: placement[:preferred_side]
          )
          start_wall_place_animation(args) if placed
        end
      end
      @dragged_wall = nil
      @last_hovered_wall_placement = nil
      return
    end

    return unless mouse_pressed?(args)

    clickable_placement = available_click_wall_placement(args, board_x, board_y)
    if clickable_placement
      wall = current_player_wall_piece
      if wall
        placed = game.place_wall_in_well_with_side(
          wall,
          clickable_placement[:wall_well],
          preferred_side: clickable_placement[:preferred_side]
        )
        start_wall_place_animation(args) if placed
      end
      return
    end

    game.reserve_wall_rects(args, board_x, board_y).each do |wall, rect|
      next if rect.nil?
      next unless wall.player == game.current_player
      next unless mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])

      @dragged_wall = wall
      @last_hovered_wall_placement = nil
      @drag_offset_x = rect[:w] / 2
      @drag_offset_y = rect[:h] / 2
      break
    end
  end

  def hovered_available_wall_placement(args, board_x, board_y, use_last_hovered: true)
    return nil if dragged_wall.nil?

    hovered_wall_placement_for(args, board_x, board_y, wall: dragged_wall, use_last_hovered: use_last_hovered)
  end

  def available_click_wall_placement(args, board_x, board_y)
    return nil unless human_turn?
    return nil if dragged_wall
    return nil if dragged_pawn

    wall = current_player_wall_piece
    return nil if wall.nil?

    hovered_wall_placement_for(args, board_x, board_y, wall: wall, use_last_hovered: true)
  end

  def hovered_wall_placement_for(args, board_x, board_y, wall:, use_last_hovered:)
    game.board.wall_wells.each do |wall_well|
      next false if wall_well.occupied?

      rect = wall_well.rect(
        board_x,
        board_y,
        cell_width: cell_size,
        cell_height: cell_size,
        cell_gap: cell_gap
      )
      next false unless mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])

      preferred_side = preferred_wall_side(args, wall_well, rect)
      wall_span = game.board.wall_span_from(wall_well, preferred_side: preferred_side)
      next false unless game.can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

      placement = { wall_well: wall_well, preferred_side: preferred_side, wall_span: wall_span }
      @last_hovered_wall_placement = placement
      return placement
    end

    return nil unless use_last_hovered
    return nil if @last_hovered_wall_placement.nil?
    unless mouse_inside_last_wall_placement?(args, board_x, board_y, @last_hovered_wall_placement)
      @last_hovered_wall_placement = nil
      return nil
    end

    if game.can_place_wall_in_well?(
      wall,
      @last_hovered_wall_placement[:wall_well],
      preferred_side: @last_hovered_wall_placement[:preferred_side]
    )
      return @last_hovered_wall_placement
    end

    @last_hovered_wall_placement = nil
    nil
  end

  def mouse_inside_last_wall_placement?(args, board_x, board_y, placement)
    rect = last_wall_placement_retention_rect(board_x, board_y, placement)
    mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
  end

  def last_wall_placement_retention_rect(board_x, board_y, placement)
    wells = Array(placement[:wall_span])
    wells = [placement[:wall_well]] if wells.empty?
    rects = wells.map do |wall_well|
      wall_well.rect(
        board_x,
        board_y,
        cell_width: cell_size,
        cell_height: cell_size,
        cell_gap: cell_gap
      )
    end

    min_x = rects.map { |rect| rect[:x] }.min
    min_y = rects.map { |rect| rect[:y] }.min
    max_x = rects.map { |rect| rect[:x] + rect[:w] }.max
    max_y = rects.map { |rect| rect[:y] + rect[:h] }.max

    {
      x: min_x,
      y: min_y,
      w: max_x - min_x,
      h: max_y - min_y
    }
  end

  def update_pawn_drag_state(args, board_x, board_y)
    if mouse_released?(args)
      if dragged_pawn
        square = hovered_square(args, board_x, board_y)
        moved = game.move_pawn_to(dragged_pawn, square.col, square.row) if square
        start_pawn_move_animation(args) if moved
      end
      clear_dragged_pawn
      return
    end

    return unless mouse_pressed?(args)
    return if dragged_wall
    return if dragged_pawn

    clickable_target = available_click_move_target(args, board_x, board_y)
    if clickable_target
      pawn = current_player_pawn
      moved = game.move_pawn_to(pawn, clickable_target.col, clickable_target.row) if pawn
      start_pawn_move_animation(args) if moved
      return
    end

    pawn = game.pawns.find do |candidate|
      next false unless candidate.player == game.current_player

      rect = pawn_rect(candidate, board_x, board_y)
      mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
    end

    return if pawn.nil?

    rect = pawn_rect(pawn, board_x, board_y)
    @dragged_pawn = pawn
    @dragged_pawn_offset_x = mouse_x(args) - rect[:x]
    @dragged_pawn_offset_y = mouse_y(args) - rect[:y]
  end

  def hovered_square(args, board_x, board_y)
    game.board.squares.find do |square|
      x = board_x + (square.col * (cell_size + cell_gap))
      y = board_y + (square.row * (cell_size + cell_gap))
      mouse_inside_rect?(args, x: x, y: y, w: cell_size, h: cell_size)
    end
  end

  def available_pawn_drop_target(args, board_x, board_y)
    return nil if dragged_pawn.nil?

    square = hovered_square(args, board_x, board_y)
    return nil if square.nil?
    return nil unless game.can_move_pawn_to?(dragged_pawn, square.col, square.row)

    square
  end

  def available_click_move_target(args, board_x, board_y)
    return nil unless human_turn?
    return nil if dragged_wall
    return nil if dragged_pawn

    square = hovered_square(args, board_x, board_y)
    return nil if square.nil?

    pawn = current_player_pawn
    return nil if pawn.nil?
    return nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

    square
  end

  def clickable_pawn_origin_square(args, board_x, board_y, clickable_target)
    return nil if clickable_target.nil?

    pawn = current_player_pawn
    return nil if pawn.nil?

    game.board.square_at(pawn.col, pawn.row)
  end

  def preferred_wall_side(args, wall_well, rect)
    if wall_well.orientation == :horizontal
      mouse_x(args) < rect[:x] + (rect[:w] / 2) ? :negative : :positive
    else
      mouse_y(args) < rect[:y] + (rect[:h] / 2) ? :negative : :positive
    end
  end

  def game
    @game ||= Game.new(
      cell_width: cell_size,
      cell_height: cell_size,
      cell_gap: cell_gap,
      mode: @mode,
      player_count: @player_count,
      player_types: @player_types
    )
  end

  def human_turn?
    game.current_controller.is_a?(HumanController)
  end

  def current_player_wall_piece
    game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  end

  def current_player_pawn
    game.pawns.find { |candidate| candidate.player == game.current_player }
  end

  def mouse_inside_rect?(args, x:, y:, w:, h:)
    mouse = args.inputs.mouse
    return false unless mouse
    return false if mouse.x.nil? || mouse.y.nil?

    mouse.x >= x &&
      mouse.x <= x + w &&
      mouse.y >= y &&
      mouse.y <= y + h
  end

  def dragged_wall
    @dragged_wall
  end

  def dragged_pawn
    @dragged_pawn
  end

  def dragged_pawn_offset_x
    @dragged_pawn_offset_x || 0
  end

  def dragged_pawn_offset_y
    @dragged_pawn_offset_y || 0
  end

  def clear_dragged_pawn
    @dragged_pawn = nil
    @dragged_pawn_offset_x = nil
    @dragged_pawn_offset_y = nil
  end

  def pawn_rect(pawn, board_x, board_y)
    cell_x = board_x + (pawn.col * (cell_size + cell_gap))
    cell_y = board_y + (pawn.row * (cell_size + cell_gap))

    {
      x: cell_x + ((cell_size - Pawn::PAWN_SIZE) / 2),
      y: cell_y + ((cell_size - Pawn::PAWN_SIZE) / 2),
      w: Pawn::PAWN_SIZE,
      h: Pawn::PAWN_SIZE
    }
  end

  def board_pixel_size
    (board_size * cell_size) + ((board_size - 1) * cell_gap)
  end

  def move_animation_in_progress?(args)
    pawn_move_animation_in_progress?(args) || wall_place_animation_in_progress?(args)
  end

  def pawn_move_animation_in_progress?(args)
    return false if @pawn_move_animation_until_tick.nil?

    tick_count(args) < @pawn_move_animation_until_tick
  end

  def start_pawn_move_animation(args)
    @pawn_move_animation_until_tick = tick_count(args) + PawnRenderer::MOVE_ANIMATION_TICKS
  end

  def wall_place_animation_in_progress?(args)
    return false if @wall_place_animation_until_tick.nil?

    tick_count(args) < @wall_place_animation_until_tick
  end

  def start_wall_place_animation(args)
    @wall_place_animation_until_tick = tick_count(args) + WallRenderer::PLACE_ANIMATION_TICKS
  end

  def game_screen_renderer
    @game_screen_renderer ||= GameScreenRenderer.new
  end


  def mouse_x(args)
    args.inputs.mouse.x || 0
  end

  def mouse_y(args)
    args.inputs.mouse.y || 0
  end

  def mouse_pressed?(args)
    mouse = args.inputs.mouse
    return false unless mouse

    !!mouse.down
  end

  def mouse_released?(args)
    mouse = args.inputs.mouse
    return false unless mouse

    !!mouse.up
  end

  def menu_pressed?(args)
    args.inputs.keyboard.key_down.escape
  end

  def tick_count(args)
    return 0 unless args.respond_to?(:state) && args.state

    args.state.tick_count || 0
  end
end
