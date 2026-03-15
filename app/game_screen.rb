class GameScreen
  BOARD_SIZE = 9
  CELL_SIZE = 48
  CELL_GAP = 6
  BOARD_PIXEL_SIZE = (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * CELL_GAP)

  def tick(args)
    args.outputs.background_color = [10, 10, 12]

    board_x = ((args.grid.w - BOARD_PIXEL_SIZE) / 2).to_i
    board_y = 120

    draw_board(args, board_x, board_y)
    draw_wall_wells(args, board_x, board_y)
    draw_wall_reserves(args, board_x, board_y)
    update_pawn_drag_state(args, board_x, board_y)
    draw_available_pawn_drop_target(args, board_x, board_y)
    draw_player_names(args, board_x, board_y)
    draw_pawns(args, board_x, board_y)
  end

  private

  def draw_board(args, board_x, board_y)
    args.outputs.borders << {
      x: board_x - 10,
      y: board_y - 10,
      w: BOARD_PIXEL_SIZE + 20,
      h: BOARD_PIXEL_SIZE + 20,
      r: 190,
      g: 190,
      b: 190
    }

    game.board.squares.each do |square|
      square.render(args, board_x, board_y, CELL_GAP)
    end
  end

  def draw_wall_reserves(args, board_x, board_y)
    wall_count = Game::WALLS_PER_LANE
    spacing = 10
    wall_w = game.walls[0].width
    total_w = (wall_count * wall_w) + ((wall_count - 1) * spacing)
    start_x = ((args.grid.w - total_w) / 2).to_i

    top_y = board_y + BOARD_PIXEL_SIZE + 36
    bottom_y = board_y - 46

    wall_rects = {}

    game.walls.each do |wall|
      next if wall.placed?
      x = start_x + (wall.slot * (wall_w + spacing))
      y = wall.lane == :top ? top_y : bottom_y
      wall_rects[wall] = { x: x, y: y, w: wall.width, h: wall.height }
    end

    update_wall_drag_state(args, wall_rects, board_x, board_y)

    wall_rects.each do |wall, rect|
      x = rect[:x]
      y = rect[:y]
      if wall == dragged_wall
        x = mouse_x(args) - drag_offset_x
        y = mouse_y(args) - drag_offset_y
      end

      wall.render(args, x, y)
      draw_hover_border_if_needed(args, wall, x, y)
    end

  end

  def draw_wall_wells(args, board_x, board_y)
    game.board.wall_wells.each do |wall_well|
      wall_well.render(
        args,
        board_x,
        board_y,
        cell_width: CELL_SIZE,
        cell_height: CELL_SIZE,
        cell_gap: CELL_GAP
      )
    end
  end

  def draw_hover_border_if_needed(args, wall, x, y)
    return unless wall.player == game.current_player
    return unless mouse_inside_rect?(args, x: x, y: y, w: wall.width, h: wall.height)

    args.outputs.borders << {
      x: x - 1,
      y: y - 1,
      w: wall.width + 2,
      h: wall.height + 2,
      r: 240,
      g: 60,
      b: 60
    }
  end

  def update_wall_drag_state(args, wall_rects, board_x, board_y)
    if mouse_released?(args)
      if dragged_wall
        wall_well = hovered_available_wall_well(args, board_x, board_y)
        game.place_wall_in_well(dragged_wall, wall_well) if wall_well
      end
      @dragged_wall = nil
      return
    end

    return unless mouse_pressed?(args)

    game.walls.each do |wall|
      rect = wall_rects[wall]
      next if rect.nil?
      next unless wall.player == game.current_player
      next unless mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])

      @dragged_wall = wall
      @drag_offset_x = mouse_x(args) - rect[:x]
      @drag_offset_y = mouse_y(args) - rect[:y]
      break
    end
  end

  def hovered_available_wall_well(args, board_x, board_y)
    game.board.wall_wells.find do |wall_well|
      next false if wall_well.occupied?

      rect = wall_well.rect(
        board_x,
        board_y,
        cell_width: CELL_SIZE,
        cell_height: CELL_SIZE,
        cell_gap: CELL_GAP
      )
      mouse_inside_rect?(args, x: rect[:x], y: rect[:y], w: rect[:w], h: rect[:h])
    end
  end

  def draw_pawns(args, board_x, board_y)
    game.pawns.each do |pawn|
      if pawn == dragged_pawn
        pawn.render_at(args, dragged_pawn_x(args), dragged_pawn_y(args))
      else
        pawn.render(args, board_x, board_y, CELL_GAP)
      end
    end
  end

  def draw_available_pawn_drop_target(args, board_x, board_y)
    return if dragged_pawn.nil?

    square = hovered_square(args, board_x, board_y)
    return if square.nil?
    return unless game.can_move_pawn_to?(dragged_pawn, square.col, square.row)

    x = board_x + (square.col * (CELL_SIZE + CELL_GAP))
    y = board_y + (square.row * (CELL_SIZE + CELL_GAP))

    args.outputs.borders << {
      x: x - 2,
      y: y - 2,
      w: CELL_SIZE + 4,
      h: CELL_SIZE + 4,
      r: 240,
      g: 60,
      b: 60
    }
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
      x = board_x + (square.col * (CELL_SIZE + CELL_GAP))
      y = board_y + (square.row * (CELL_SIZE + CELL_GAP))
      mouse_inside_rect?(args, x: x, y: y, w: CELL_SIZE, h: CELL_SIZE)
    end
  end

  def draw_player_names(args, board_x, board_y)
    top_name = game.players[1].name
    bottom_name = game.players[0].name
    center_x = board_x + (BOARD_PIXEL_SIZE / 2)

    args.outputs.labels << {
      x: center_x,
      y: board_y + BOARD_PIXEL_SIZE + 78,
      text: top_name,
      alignment_enum: 1,
      size_enum: 2,
      r: 235,
      g: 235,
      b: 235
    }

    args.outputs.labels << {
      x: center_x,
      y: board_y - 80,
      text: bottom_name,
      alignment_enum: 1,
      size_enum: 2,
      r: 235,
      g: 235,
      b: 235
    }
  end

  def game
    @game ||= Game.new(cell_width: CELL_SIZE, cell_height: CELL_SIZE)
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

  def drag_offset_x
    @drag_offset_x || 0
  end

  def drag_offset_y
    @drag_offset_y || 0
  end

  def dragged_pawn_offset_x
    @dragged_pawn_offset_x || 0
  end

  def dragged_pawn_offset_y
    @dragged_pawn_offset_y || 0
  end

  def dragged_pawn_x(args)
    mouse_x(args) - dragged_pawn_offset_x
  end

  def dragged_pawn_y(args)
    mouse_y(args) - dragged_pawn_offset_y
  end

  def clear_dragged_pawn
    @dragged_pawn = nil
    @dragged_pawn_offset_x = nil
    @dragged_pawn_offset_y = nil
  end

  def pawn_rect(pawn, board_x, board_y)
    cell_x = board_x + (pawn.col * (CELL_SIZE + CELL_GAP))
    cell_y = board_y + (pawn.row * (CELL_SIZE + CELL_GAP))

    {
      x: cell_x + ((CELL_SIZE - Pawn::PAWN_SIZE) / 2),
      y: cell_y + ((CELL_SIZE - Pawn::PAWN_SIZE) / 2),
      w: Pawn::PAWN_SIZE,
      h: Pawn::PAWN_SIZE
    }
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
