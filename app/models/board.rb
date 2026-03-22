require "app/models/square.rb"
require "app/models/wall_well.rb"
require "app/models/path_distance_calculator.rb"

class Board
  attr_reader :squares, :wall_wells, :size, :cell_width, :cell_height

  def initialize(size: 9, cell_width:, cell_height:)
    @size = size
    @cell_width = cell_width
    @cell_height = cell_height
    @squares = build_squares
    @horizontal_wall_wells = {}
    @vertical_wall_wells = {}
    @wall_wells = build_wall_wells
  end

  def square_at(col, row)
    return nil unless inside_bounds?(col, row)

    squares.find { |square| square.col == col && square.row == row }
  end

  def path_blocked?(from_col:, from_row:, to_col:, to_row:, extra_occupied_wall_wells: nil)
    wall_well = wall_well_between(from_col: from_col, from_row: from_row, to_col: to_col, to_row: to_row)
    wall_well_occupied?(wall_well, extra_occupied_wall_wells: extra_occupied_wall_wells)
  end

  def path_exists?(start_col:, start_row:, goal_row: nil, goal_col: nil, extra_occupied_wall_wells: nil)
    frontier = [{ col: start_col, row: start_row }]
    visited = { "#{start_col},#{start_row}" => true }

    until frontier.empty?
      current = frontier.shift
      return true if reached_goal?(current[:col], current[:row], goal_row: goal_row, goal_col: goal_col)

      neighbor_positions(
        current[:col],
        current[:row],
        extra_occupied_wall_wells: extra_occupied_wall_wells
      ).each do |neighbor|
        key = "#{neighbor[:col]},#{neighbor[:row]}"
        next if visited[key]

        visited[key] = true
        frontier << neighbor
      end
    end

    false
  end

  def shortest_distance_to_goal(start_col:, start_row:, goal_row: nil, goal_col: nil, extra_occupied_wall_wells: nil)
    player = Struct.new(:winning_row, :winning_col) do
      def goal_reached?(col, row)
        return true if !winning_row.nil? && row == winning_row
        return true if !winning_col.nil? && col == winning_col

        false
      end
    end.new(goal_row, goal_col)

    path_distance_calculator.shortest_distance_to_goal(
      board: self,
      start_col: start_col,
      start_row: start_row,
      player: player,
      extra_occupied_wall_wells: extra_occupied_wall_wells
    )
  end

  def wall_span_from(wall_well, preferred_side: :positive)
    return nil if wall_well.nil?

    if wall_well.orientation == :horizontal
      second_well = wall_well_at(
        :horizontal,
        wall_well.col + span_offset(preferred_side),
        wall_well.row
      )
    else
      second_well = wall_well_at(
        :vertical,
        wall_well.col,
        wall_well.row + span_offset(preferred_side)
      )
    end

    return nil if second_well.nil?

    [wall_well, second_well].sort_by do |candidate|
      wall_well.orientation == :horizontal ? candidate.col : candidate.row
    end
  end

  private

  def build_squares
    squares = []
    color = [0, 0, 0]

    size.times do |row|
      size.times do |col|
        squares << Square.new(col, row, color, cell_width: cell_width, cell_height: cell_height)
      end
    end

    squares
  end

  def build_wall_wells
    wells = []

    (size - 1).times do |row|
      size.times do |col|
        wall_well = WallWell.new(
          col: col,
          row: row,
          width: 36,
          height: 10,
          orientation: :horizontal
        )
        wells << wall_well
        @horizontal_wall_wells[[col, row]] = wall_well
      end
    end

    size.times do |row|
      (size - 1).times do |col|
        wall_well = WallWell.new(
          col: col,
          row: row,
          width: 10,
          height: 36,
          orientation: :vertical
        )
        wells << wall_well
        @vertical_wall_wells[[col, row]] = wall_well
      end
    end

    wells
  end

  def inside_bounds?(col, row)
    col >= 0 && col < size && row >= 0 && row < size
  end

  def wall_well_between(from_col:, from_row:, to_col:, to_row:)
    if from_col == to_col
      lower_row = [from_row, to_row].min
      wall_well_at(:horizontal, from_col, lower_row)
    elsif from_row == to_row
      lower_col = [from_col, to_col].min
      wall_well_at(:vertical, lower_col, from_row)
    end
  end

  def wall_well_at(orientation, col, row)
    if orientation == :horizontal
      @horizontal_wall_wells[[col, row]]
    else
      @vertical_wall_wells[[col, row]]
    end
  end

  def neighbor_positions(col, row, extra_occupied_wall_wells:)
    [
      { col: col + 1, row: row },
      { col: col - 1, row: row },
      { col: col, row: row + 1 },
      { col: col, row: row - 1 }
    ].select do |neighbor|
      inside_bounds?(neighbor[:col], neighbor[:row]) &&
        !path_blocked?(
          from_col: col,
          from_row: row,
          to_col: neighbor[:col],
          to_row: neighbor[:row],
          extra_occupied_wall_wells: extra_occupied_wall_wells
        )
    end
  end

  def wall_well_occupied?(wall_well, extra_occupied_wall_wells:)
    return false if wall_well.nil?
    return true if Array(extra_occupied_wall_wells).include?(wall_well)

    wall_well.occupied?
  end

  def span_offset(preferred_side)
    preferred_side == :negative ? -1 : 1
  end

  def reached_goal?(col, row, goal_row:, goal_col:)
    return true if !goal_row.nil? && row == goal_row
    return true if !goal_col.nil? && col == goal_col

    false
  end

  def path_distance_calculator
    @path_distance_calculator ||= PathDistanceCalculator.new
  end
end
