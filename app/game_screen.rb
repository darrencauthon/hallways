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
    draw_wall_reserves(args, board_x, board_y)
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
    wall_h = game.walls[0].height
    total_w = (wall_count * wall_w) + ((wall_count - 1) * spacing)
    start_x = ((args.grid.w - total_w) / 2).to_i

    top_y = board_y + BOARD_PIXEL_SIZE + 36
    bottom_y = board_y - 46

    game.walls.each do |wall|
      x = start_x + (wall.slot * (wall_w + spacing))
      y = wall.lane == :top ? top_y : bottom_y
      wall.render(args, x, y)
      draw_hover_border_if_needed(args, wall, x, y)
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

  def draw_pawns(args, board_x, board_y)
    game.pawns.each do |pawn|
      pawn.render(args, board_x, board_y, CELL_GAP)
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
end
