class SetupScreen
  PLAYER_TYPES = [:human, :computer].freeze
  MENU_ROWS = [:player_one, :player_two, :play].freeze
  MENU_X_CENTER = 640
  MENU_Y_START = 290
  MENU_Y_STEP = 60
  MENU_HOVER_HALF_HEIGHT = 26
  MENU_HOVER_X_PADDING = 260

  def initialize
    @player_types = [:human, :human]
  end

  def tick(args)
    handle_input(args)

    args.outputs.background_color = [18, 20, 28]
    args.outputs.labels << {
      x: 640,
      y: 410,
      text: "2 Player Setup",
      alignment_enum: 1,
      size_enum: 5,
      r: 240,
      g: 240,
      b: 240
    }

    render_rows(args)
    return [:start_game, { player_types: @player_types.dup }] if play_confirmed?(args)

    nil
  end

  private

  def handle_input(args)
    hovered_index = hovered_row_index(args)
    @selected_row_index = hovered_index unless hovered_index.nil?

    if up_pressed?(args)
      select_previous_row
    elsif down_pressed?(args)
      select_next_row
    end

    if selected_row == :player_one
      toggle_player_type(0) if left_pressed?(args) || right_pressed?(args) || mouse_clicked_row?(args, :player_one)
    elsif selected_row == :player_two
      toggle_player_type(1) if left_pressed?(args) || right_pressed?(args) || mouse_clicked_row?(args, :player_two)
    end
  end

  def render_rows(args)
    MENU_ROWS.each_with_index do |row, index|
      selected = index == selected_row_index
      text = row_text(row)
      args.outputs.labels << {
        x: MENU_X_CENTER,
        y: row_y(index),
        text: selected ? "> #{text} <" : text,
        alignment_enum: 1,
        size_enum: row == :play ? 5 : 3,
        r: selected ? 255 : 175,
        g: selected ? 220 : 175,
        b: selected ? 100 : 175
      }
    end
  end

  def row_text(row)
    if row == :player_one
      "Player 1: #{display_type(@player_types[0])}"
    elsif row == :player_two
      "Player 2: #{display_type(@player_types[1])}"
    else
      "Play"
    end
  end

  def display_type(type)
    type == :computer ? "Computer" : "Human"
  end

  def toggle_player_type(player_index)
    current_type = @player_types[player_index]
    @player_types[player_index] = current_type == :human ? :computer : :human
  end

  def play_confirmed?(args)
    selected_row == :play && (confirm_pressed?(args) || mouse_clicked_row?(args, :play))
  end

  def selected_row
    MENU_ROWS[selected_row_index]
  end

  def selected_row_index
    @selected_row_index ||= 0
  end

  def select_next_row
    @selected_row_index = (selected_row_index + 1) % MENU_ROWS.length
  end

  def select_previous_row
    @selected_row_index = (selected_row_index - 1) % MENU_ROWS.length
  end

  def hovered_row_index(args)
    mouse = args.inputs.mouse
    return nil unless mouse
    return nil if mouse.x.nil? || mouse.y.nil?

    MENU_ROWS.each_with_index do |_row, index|
      y = row_y(index)
      if mouse.x >= (MENU_X_CENTER - MENU_HOVER_X_PADDING) &&
         mouse.x <= (MENU_X_CENTER + MENU_HOVER_X_PADDING) &&
         mouse.y >= (y - MENU_HOVER_HALF_HEIGHT) &&
         mouse.y <= (y + MENU_HOVER_HALF_HEIGHT)
        return index
      end
    end

    nil
  end

  def mouse_clicked_row?(args, row)
    mouse = args.inputs.mouse
    return false unless mouse
    return false unless mouse.down

    index = hovered_row_index(args)
    return false if index.nil?

    MENU_ROWS[index] == row
  end

  def row_y(index)
    MENU_Y_START - (index * MENU_Y_STEP)
  end

  def up_pressed?(args)
    args.inputs.keyboard.key_down.up
  end

  def down_pressed?(args)
    args.inputs.keyboard.key_down.down
  end

  def left_pressed?(args)
    args.inputs.keyboard.key_down.left
  end

  def right_pressed?(args)
    args.inputs.keyboard.key_down.right
  end

  def confirm_pressed?(args)
    args.inputs.keyboard.key_down.enter
  end
end
