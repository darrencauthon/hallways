class ComputerPlayerController < NullPlayerController
  def next_action(args:, game:)
    pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return nil if pawn.nil?

    moves = game.board.squares.select do |square|
      game.can_move_pawn_to?(pawn, square.col, square.row)
    end
    return nil if moves.empty?

    move = moves.sample
    {
      type: :move_pawn,
      pawn: pawn,
      col: move.col,
      row: move.row
    }
  end
end
