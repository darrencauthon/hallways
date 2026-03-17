class ComputerController < NullController
  def next_action(args:, game:)
    actions = pawn_actions(game) + wall_actions(game)
    return nil if actions.empty?

    actions.sample
  end

  private

  def pawn_actions(game)
    pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return [] if pawn.nil?

    game.board.squares.filter_map do |square|
      next nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

      {
        type: :move_pawn,
        pawn: pawn,
        col: square.col,
        row: square.row
      }
    end
  end

  def wall_actions(game)
    wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
    return [] if wall.nil?

    game.board.wall_wells.flat_map do |wall_well|
      [:negative, :positive].filter_map do |preferred_side|
        next nil unless game.can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

        {
          type: :place_wall,
          wall: wall,
          wall_well: wall_well,
          preferred_side: preferred_side
        }
      end
    end
  end
end
