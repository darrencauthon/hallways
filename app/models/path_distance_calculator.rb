class PathDistanceCalculator
  def shortest_distance_to_goal(board:, start_col:, start_row:, player:, extra_occupied_wall_wells: nil)
    return 0 if player.goal_reached?(start_col, start_row)

    frontier = [{ col: start_col, row: start_row, distance: 0 }]
    visited = { key_for(start_col, start_row) => true }

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

        return current[:distance] + 1 if player.goal_reached?(neighbor[:col], neighbor[:row])

        visited[key] = true
        frontier << {
          col: neighbor[:col],
          row: neighbor[:row],
          distance: current[:distance] + 1
        }
      end
    end

    nil
  end

  private

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
