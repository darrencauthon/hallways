class Pawn
  PAWN_SIZE = 28
  PAWN_SPRITE_PATH = "sprites/solid-circle.png".freeze

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
      path: PAWN_SPRITE_PATH,
      r: color[0],
      g: color[1],
      b: color[2],
      a: 255
    }
  end

  def move_to(col, row)
    @col = col
    @row = row
  end
end
