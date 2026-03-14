class Player
  attr_reader :name, :game

  def initialize(name, game:)
    @name = name
    @game = game
  end
end
