class Player
  attr_reader :name, :game

  def initialize(name, game:)
    @name = name
    @game = game
  end

  def my_turn?
    game.current_player == self
  end
end
