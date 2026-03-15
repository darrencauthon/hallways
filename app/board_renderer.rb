class BoardRenderer
  def initialize(cell_size:, cell_gap:, board_pixel_size:)
    @cell_size = cell_size
    @cell_gap = cell_gap
    @board_pixel_size = board_pixel_size
  end

  def render(args, game, board_x, board_y)
    args.outputs.borders << {
      x: board_x - 10,
      y: board_y - 10,
      w: @board_pixel_size + 20,
      h: @board_pixel_size + 20,
      r: 190,
      g: 190,
      b: 190
    }

    game.board.squares.each do |square|
      square.render(args, board_x, board_y, @cell_gap)
    end

    game.board.wall_wells.each do |wall_well|
      wall_well.render(
        args,
        board_x,
        board_y,
        cell_width: @cell_size,
        cell_height: @cell_size,
        cell_gap: @cell_gap
      )
    end
  end
end
