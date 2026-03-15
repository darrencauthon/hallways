class Player
  attr_reader :name, :game, :winning_row

  def initialize(name, game:, winning_row:)
    @name = name
    @game = game
    @winning_row = winning_row
  end

  def my_turn?
    game.current_player == self
  end
end
