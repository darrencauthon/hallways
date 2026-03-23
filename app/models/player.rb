class Player
  attr_reader :name, :game, :winning_row, :winning_col, :controller, :image

  def initialize(name, game:, winning_row:, winning_col: nil, controller:, image: nil)
    @name = name
    @game = game
    @winning_row = winning_row
    @winning_col = winning_col
    @controller = controller
    @image = image
  end

  def my_turn?
    game.current_player == self
  end

  def turn_indicator_text
    return nil unless my_turn?

    controller.turn_indicator_text
  end

  def goal_reached?(col, row)
    return true if !winning_row.nil? && row == winning_row
    return true if !winning_col.nil? && col == winning_col

    false
  end

  def goal_axis
    return :row unless winning_row.nil?

    :col
  end
end
