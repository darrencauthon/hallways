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
    game_screen_renderer.render_background(args)

    board_x = ((args.grid.w - board_pixel_size) / 2).to_i

    @computer_thinking = false
    apply_current_controller_action(args)
    if human_turn?
      update_wall_drag_state(args, board_x, board_y)
      update_pawn_drag_state(args, board_x, board_y)
    else
      @dragged_wall = nil
      clear_dragged_pawn
    end
    wall_drop_target = hovered_available_wall_placement(args, board_x, board_y, use_last_hovered: false) if dragged_wall
    pawn_drop_target = available_pawn_drop_target(args, board_x, board_y)
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
      pawn_drop_target: pawn_drop_target
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
      game.move_pawn_to(action[:pawn], action[:col], action[:row])
      @computer_thinking = false
    elsif action[:type] == :place_wall
      game.place_wall_in_well_with_side(
        action[:wall],
        action[:wall_well],
        preferred_side: action[:preferred_side]
      )
      @computer_thinking = false
    end
  end

  def update_wall_drag_state(args, board_x, board_y)
    if mouse_released?(args)
      if dragged_wall
        placement = hovered_available_wall_placement(args, board_x, board_y, use_last_hovered: false)
        if placement
          game.place_wall_in_well_with_side(
            dragged_wall,
            placement[:wall_well],
            preferred_side: placement[:preferred_side]
          )
        end
      end
      @dragged_wall = nil
      @last_hovered_wall_placement = nil
      return
    end

    return unless mouse_pressed?(args)

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
      next false unless game.can_place_wall_in_well?(dragged_wall, wall_well, preferred_side: preferred_side)

      placement = { wall_well: wall_well, preferred_side: preferred_side, wall_span: wall_span }
      @last_hovered_wall_placement = placement
      return placement
    end

    return nil unless use_last_hovered
    return nil unless mouse_near_board?(args, board_x, board_y)
    return nil if @last_hovered_wall_placement.nil?
    if game.can_place_wall_in_well?(
      dragged_wall,
      @last_hovered_wall_placement[:wall_well],
      preferred_side: @last_hovered_wall_placement[:preferred_side]
    )
      return @last_hovered_wall_placement
    end

    @last_hovered_wall_placement = nil
    nil
  end

  def mouse_near_board?(args, board_x, board_y)
    padding = 36
    mouse_inside_rect?(
      args,
      x: board_x - padding,
      y: board_y - padding,
      w: board_pixel_size + (padding * 2),
      h: board_pixel_size + (padding * 2)
    )
  end

  def update_pawn_drag_state(args, board_x, board_y)
    if mouse_released?(args)
      if dragged_pawn
        square = hovered_square(args, board_x, board_y)
        game.move_pawn_to(dragged_pawn, square.col, square.row) if square
      end
      clear_dragged_pawn
      return
    end

    return unless mouse_pressed?(args)
    return if dragged_wall
    return if dragged_pawn

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
end
