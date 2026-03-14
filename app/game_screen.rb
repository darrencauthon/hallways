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

    BOARD_SIZE.times do |row|
      BOARD_SIZE.times do |col|
        x, y = cell_origin(board_x, board_y, col, row)
        args.outputs.solids << {
          x: x,
          y: y,
          w: CELL_SIZE,
          h: CELL_SIZE,
          r: 225,
          g: 214,
          b: 189
        }
      end
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
    # Placeholder pawn locations: centered on opposite board edges.
    draw_pawn(args, board_x, board_y, col: 4, row: 8, color: [245, 245, 245])
    draw_pawn(args, board_x, board_y, col: 4, row: 0, color: [50, 50, 50])
  end

  def draw_pawn(args, board_x, board_y, col:, row:, color:)
    cell_x, cell_y = cell_origin(board_x, board_y, col, row)
    pawn_size = 28
    pawn_x = cell_x + ((CELL_SIZE - pawn_size) / 2)
    pawn_y = cell_y + ((CELL_SIZE - pawn_size) / 2)

    args.outputs.solids << {
      x: pawn_x,
      y: pawn_y,
      w: pawn_size,
      h: pawn_size,
      r: color[0],
      g: color[1],
      b: color[2]
    }

    args.outputs.borders << {
      x: pawn_x,
      y: pawn_y,
      w: pawn_size,
      h: pawn_size,
      r: 220,
      g: 70,
      b: 70
    }
  end

  def cell_origin(board_x, board_y, col, row)
    [
      board_x + (col * (CELL_SIZE + CELL_GAP)),
      board_y + (row * (CELL_SIZE + CELL_GAP))
    ]
  end
end
