class Player
  attr_reader :name, :game, :winning_row, :controller

  def initialize(name, game:, winning_row:, controller:)
    @name = name
    @game = game
    @winning_row = winning_row
    @controller = controller
  end

  def my_turn?
    game.current_player == self
  end

  def turn_indicator_text
    return nil unless my_turn?

    controller.turn_indicator_text
  end
end
