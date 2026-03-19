class Pawn
  PAWN_SIZE = 28
  PAWN_SPRITE_FRAME_WIDTH = 256
  PAWN_SPRITE_FRAME_HEIGHT = 256
  PAWN_SPRITE_SHEET = "sprites/pawn.png".freeze

  attr_reader :col, :row, :color, :cell_width, :cell_height, :player

  def initialize(col, row, color, player:, cell_width:, cell_height:)
    @col = col
    @row = row
    @color = color
    @player = player
    @cell_width = cell_width
    @cell_height = cell_height
  end

  def render(args, board_x, board_y, cell_gap)
    cell_x = board_x + (col * (cell_width + cell_gap))
    cell_y = board_y + (row * (cell_height + cell_gap))
    pawn_x = cell_x + ((cell_width - PAWN_SIZE) / 2)
    pawn_y = cell_y + ((cell_height - PAWN_SIZE) / 2)

    render_at(args, pawn_x, pawn_y)
  end

  def render_at(args, pawn_x, pawn_y)
    args.outputs.sprites << {
      x: pawn_x,
      y: pawn_y,
      w: PAWN_SIZE,
      h: PAWN_SIZE,
      path: PAWN_SPRITE_SHEET,
      source_x: sprite_frame_index * PAWN_SPRITE_FRAME_WIDTH,
      source_y: 0,
      source_w: PAWN_SPRITE_FRAME_WIDTH,
      source_h: PAWN_SPRITE_FRAME_HEIGHT
    }
  end

  def move_to(col, row)
    @col = col
    @row = row
  end

  private

  def sprite_frame_index
    game = player.respond_to?(:game) ? player.game : nil
    players = game.respond_to?(:players) ? game.players : nil
    if players && players[0] == player
      return 0
    elsif players && players[1] == player
      return 1
    end

    brightness = color[0] + color[1] + color[2]
    return 0 if brightness >= 400

    1
  end
end
