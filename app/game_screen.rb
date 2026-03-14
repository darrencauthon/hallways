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

    game.squares.each do |square|
      square.render(args, board_x, board_y, CELL_GAP)
    end
  end

  def draw_wall_reserves(args, board_x, board_y)
    wall_count = 10
    wall_w = 36
    wall_h = 10
    spacing = 10
    total_w = (wall_count * wall_w) + ((wall_count - 1) * spacing)
    start_x = ((args.grid.w - total_w) / 2).to_i

    top_y = board_y + BOARD_PIXEL_SIZE + 36
    bottom_y = board_y - 46

    wall_count.times do |index|
      x = start_x + (index * (wall_w + spacing))
      args.outputs.solids << { x: x, y: top_y, w: wall_w, h: wall_h, r: 210, g: 165, b: 95 }
      args.outputs.solids << { x: x, y: bottom_y, w: wall_w, h: wall_h, r: 210, g: 165, b: 95 }
    end

    args.outputs.labels << {
      x: board_x + (BOARD_PIXEL_SIZE / 2),
      y: top_y + 30,
      text: "Top Walls",
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 220
    }

    args.outputs.labels << {
      x: board_x + (BOARD_PIXEL_SIZE / 2),
      y: bottom_y - 10,
      text: "Bottom Walls",
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 220
    }
  end

  def draw_pawns(args, board_x, board_y)
    game.pawns.each do |pawn|
      pawn.render(args, board_x, board_y, CELL_GAP)
    end
  end

  def game
    @game ||= Game.new(cell_width: CELL_SIZE, cell_height: CELL_SIZE)
  end
end
