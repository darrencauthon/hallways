class Pawn
  PAWN_SIZE = 28
  WHITE_PAWN_SPRITE = "sprites/pawn_white.png".freeze
  BLACK_PAWN_SPRITE = "sprites/pawn_black.png".freeze

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
      path: sprite_path
    }
  end

  def move_to(col, row)
    @col = col
    @row = row
  end

  private

  def sprite_path
    brightness = color[0] + color[1] + color[2]
    return WHITE_PAWN_SPRITE if brightness >= 400

    BLACK_PAWN_SPRITE
  end
end
