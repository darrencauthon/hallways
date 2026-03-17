class LastLineBotController < BotController
  def next_action(args:, game:)
    return nil if game.winner

    my_pawn = game.pawns.find { |candidate| candidate.player == game.current_player }
    return nil if my_pawn.nil?

    opponent_pawn = game.pawns.find { |candidate| candidate.player != game.current_player }
    return best_blocking_wall_action(game, opponent_pawn) || best_move_action(game, my_pawn) if should_block_opponent?(opponent_pawn)

    best_move_action(game, my_pawn)
  end

  private

  def should_block_opponent?(opponent_pawn)
    return false if opponent_pawn.nil?

    rows_from_goal = (opponent_pawn.player.winning_row - opponent_pawn.row).abs
    rows_from_goal <= 2
  end

  def best_blocking_wall_action(game, opponent_pawn)
    wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
    return nil if wall.nil?
    return nil if opponent_pawn.nil?

    baseline = distance_to_goal_row(
      game.board,
      opponent_pawn.col,
      opponent_pawn.row,
      opponent_pawn.player.winning_row,
      extra_occupied_wall_wells: nil
    )
    return nil if baseline.nil?

    best_gain = 0
    best_actions = []

    game.board.wall_wells.each do |wall_well|
      [:negative, :positive].each do |preferred_side|
        next unless game.can_place_wall_in_well?(wall, wall_well, preferred_side: preferred_side)

        wall_span = game.board.wall_span_from(wall_well, preferred_side: preferred_side)
        next if wall_span.nil?

        candidate_distance = distance_to_goal_row(
          game.board,
          opponent_pawn.col,
          opponent_pawn.row,
          opponent_pawn.player.winning_row,
          extra_occupied_wall_wells: wall_span
        )
        next if candidate_distance.nil?

        gain = candidate_distance - baseline
        next if gain <= 0

        action = {
          type: :place_wall,
          wall: wall,
          wall_well: wall_well,
          preferred_side: preferred_side
        }

        if gain > best_gain
          best_gain = gain
          best_actions = [action]
        elsif gain == best_gain
          best_actions << action
        end
      end
    end

    return nil if best_actions.empty?

    best_actions.sample
  end

  def best_move_action(game, pawn)
    legal_moves = legal_pawn_moves(game, pawn)
    return nil if legal_moves.empty?

    goal_row = game.current_player.winning_row
    best_distance = nil
    best_moves = []

    legal_moves.each do |move|
      distance = distance_to_goal_row(
        game.board,
        move[:col],
        move[:row],
        goal_row,
        extra_occupied_wall_wells: nil
      )
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

  def legal_pawn_moves(game, pawn)
    game.board.squares.filter_map do |square|
      next nil unless game.can_move_pawn_to?(pawn, square.col, square.row)

      { col: square.col, row: square.row }
    end
  end

  def distance_to_goal_row(board, start_col, start_row, goal_row, extra_occupied_wall_wells:)
    return 0 if start_row == goal_row

    visited = {}
    frontier = [{ col: start_col, row: start_row, steps: 0 }]
    visited[key_for(start_col, start_row)] = true

    until frontier.empty?
      current = frontier.shift
      neighbors_for(
        board,
        current[:col],
        current[:row],
        extra_occupied_wall_wells: extra_occupied_wall_wells
      ).each do |neighbor|
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

  def neighbors_for(board, col, row, extra_occupied_wall_wells:)
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
          to_row: neighbor[:row],
          extra_occupied_wall_wells: extra_occupied_wall_wells
        )
    end
  end

  def key_for(col, row)
    "#{col},#{row}"
  end
end
