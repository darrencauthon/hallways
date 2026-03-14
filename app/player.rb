class Player
  attr_reader :name, :game, :pawn

  def initialize(name, game:)
    @name = name
    @game = game
  end

  def assign_pawn(pawn)
    @pawn = pawn
  end
end
