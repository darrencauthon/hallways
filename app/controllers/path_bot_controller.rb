class PathBotController < BotController
  def next_action(args:, game:)
    return nil if game.winner

    pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return nil if pawn.nil?

    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    goal_row = game.current_player.winning_row
    best_distance = nil
    best_moves = []

    legal_moves.each do |move|
      distance = distance_to_goal_row(game.board, move[:col], move[:row], goal_row)
      next if distance.nil?

      if best_distance.nil? || distance < best_distance
        best_distance = distance
        best_moves = [move]
      elsif distance == best_distance
        best_moves << move
      end
    end

    chosen_move = (best_moves.empty? ? legal_moves : best_moves).sample
    {
      type: :move_pawn,
      pawn: pawn,
      col: chosen_move[:col],
      row: chosen_move[:row]
    }
  end

  private

  def legal_pawn_moves(game, pawn)
    game.board.squares.filter_map do |square|
      next nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

      { col: square.col, row: square.row }
    end
  end

  def distance_to_goal_row(board, start_col, start_row, goal_row)
    return 0 if start_row == goal_row

    visited = {}
    frontier = [{ col: start_col, row: start_row, steps: 0 }]
    visited[key_for(start_col, start_row)] = true

    until frontier.empty?
      current = frontier.shift
      neighbors_for(board, current[:col], current[:row]).each do |neighbor|
        key = key_for(neighbor[:col], neighbor[:row])
        next if visited[key]

        return current[:steps] + 1 if neighbor[:row] == goal_row

        visited[key] = true
        frontier << {
          col: neighbor[:col],
          row: neighbor[:row],
          steps: current[:steps] + 1
        }
      end
    end

    nil
  end

  def neighbors_for(board, col, row)
    [
      { col: col + 1, row: row },
      { col: col - 1, row: row },
      { col: col, row: row + 1 },
      { col: col, row: row - 1 }
    ].select do |neighbor|
      board.square_at(neighbor[:col], neighbor[:row]) &&
        !board.path_blocked?(
          from_col: col,
          from_row: row,
          to_col: neighbor[:col],
          to_row: neighbor[:row]
        )
    end
  end

  def key_for(col, row)
    "#{col},#{row}"
  end
end
