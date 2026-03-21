class WallPlacementRules
  def can_place?(game:, wall:, wall_well:, preferred_side:)
    return false if game.winner
    return false if wall.nil? || wall_well.nil?
    return false if wall.player != game.current_player
    return false if wall.placed?

    wall_span = wall_span_for(game: game, wall_well: wall_well, preferred_side: preferred_side)
    return false if wall_span.nil?
    return false if wall_span.any?(&:occupied?)
    return false if crosses_existing_wall_span?(game: game, wall_span: wall_span)

    game.pawns.all? do |pawn|
      game.board.path_exists?(
        start_col: pawn.col,
        start_row: pawn.row,
        goal_row: pawn.player.winning_row,
        goal_col: pawn.player.winning_col,
        extra_occupied_wall_wells: wall_span
      )
    end
  end

  def wall_span_for(game:, wall_well:, preferred_side:)
    game.board.wall_span_from(wall_well, preferred_side: preferred_side)
  end

  private

  def crosses_existing_wall_span?(game:, wall_span:)
    game.walls.any? do |existing_wall|
      next false unless existing_wall.placed?

      spans_cross?(wall_span, existing_wall.wall_wells)
    end
  end

  def spans_cross?(first_span, second_span)
    first_orientation = first_span.first.orientation
    second_orientation = second_span.first.orientation
    return false if first_orientation == second_orientation

    first_anchor = span_anchor(first_span)
    second_anchor = span_anchor(second_span)

    first_anchor[:col] == second_anchor[:col] &&
      first_anchor[:row] == second_anchor[:row]
  end

  def span_anchor(span)
    {
      col: span.first.col,
      row: span.first.row
    }
  end
end
