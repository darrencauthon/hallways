require "app/square.rb"
require "app/wall_well.rb"

class Board
  attr_reader :squares, :wall_wells, :size, :cell_width, :cell_height

  def initialize(size: 9, cell_width:, cell_height:)
    @size = size
    @cell_width = cell_width
    @cell_height = cell_height
    @squares = build_squares
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

  def path_exists?(start_col:, start_row:, goal_row:, extra_occupied_wall_wells: nil)
    frontier = [{ col: start_col, row: start_row }]
    visited = { "#{start_col},#{start_row}" => true }

    until frontier.empty?
      current = frontier.shift
      return true if current[:row] == goal_row

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

  def wall_span_from(wall_well)
    return nil if wall_well.nil?

    if wall_well.orientation == :horizontal
      second_well = wall_wells.find do |candidate|
        candidate.orientation == :horizontal &&
          candidate.col == wall_well.col + 1 &&
          candidate.row == wall_well.row
      end
    else
      second_well = wall_wells.find do |candidate|
        candidate.orientation == :vertical &&
          candidate.col == wall_well.col &&
          candidate.row == wall_well.row + 1
      end
    end

    return nil if second_well.nil?

    [wall_well, second_well]
  end

  private

  def build_squares
    squares = []
    color = [225, 214, 189]

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
        wells << WallWell.new(
          col: col,
          row: row,
          width: 36,
          height: 10,
          orientation: :horizontal
        )
      end
    end

    size.times do |row|
      (size - 1).times do |col|
        wells << WallWell.new(
          col: col,
          row: row,
          width: 10,
          height: 36,
          orientation: :vertical
        )
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
      wall_wells.find do |wall_well|
        wall_well.orientation == :horizontal &&
          wall_well.col == from_col &&
          wall_well.row == lower_row
      end
    elsif from_row == to_row
      lower_col = [from_col, to_col].min
      wall_wells.find do |wall_well|
        wall_well.orientation == :vertical &&
          wall_well.col == lower_col &&
          wall_well.row == from_row
      end
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
end
