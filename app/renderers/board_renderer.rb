class BoardRenderer
  def initialize(cell_size:, cell_gap:, board_pixel_size:)
    @cell_size = cell_size
    @cell_gap = cell_gap
    @board_pixel_size = board_pixel_size
  end

  def render(args, game, board_x, board_y)
    args.outputs.solids << {
      x: board_x - 10,
      y: board_y - 10,
      w: @board_pixel_size + 20,
      h: @board_pixel_size + 20,
      r: 89,
      g: 36,
      b: 42
    }

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
      square.render(args, board_x, board_y, @cell_gap, color_override: goal_highlight_color_for(game, square))
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

  private

  def goal_highlight_color_for(game, square)
    current_player = game.current_player
    return nil if current_player.nil?

    on_goal_edge =
      (!current_player.winning_row.nil? && square.row == current_player.winning_row) ||
      (!current_player.winning_col.nil? && square.col == current_player.winning_col)
    return nil unless on_goal_edge

    pawn = game.pawns.find { |candidate| candidate.player == current_player }
    return nil if pawn.nil?

    pawn.color
  end
end
