class SetupScreen
  PLAYER_TYPES = [:human, :random_bot, :path_bot, :last_line_bot, :pressure_bot].freeze
  PLAYER_COUNT_OPTIONS = [2, 4].freeze
  MENU_X_CENTER = 640
  MENU_Y_START = 320
  MENU_Y_STEP = 50
  MENU_HOVER_HALF_HEIGHT = 24
  MENU_HOVER_X_PADDING = 280

  def initialize
    @player_count = 2
    @player_types = [:human, :human]
  end

  def tick(args)
    handle_input(args)

    args.outputs.background_color = [18, 20, 28]
    args.outputs.labels << {
      x: 640,
      y: 420,
      text: "Game Setup",
      alignment_enum: 1,
      size_enum: 5,
      r: 240,
      g: 240,
      b: 240
    }

    render_rows(args)
    return [:start_game, { player_count: @player_count, player_types: @player_types.dup }] if play_confirmed?(args)

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

    row = selected_row
    if row == :game_size
      cycle_player_count(1) if right_pressed?(args) || mouse_clicked_row?(args, :game_size)
      cycle_player_count(-1) if left_pressed?(args)
    elsif player_row?(row)
      player_index = player_index_for_row(row)
      cycle_player_type(player_index, -1) if left_pressed?(args)
      cycle_player_type(player_index, 1) if right_pressed?(args) || mouse_clicked_row?(args, row)
    end
  end

  def render_rows(args)
    visible_rows.each_with_index do |row, index|
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

  def visible_rows
    rows = [:game_size, :player_one, :player_two]
    if @player_count == 4
      rows << :player_three
      rows << :player_four
    end
    rows << :play
    rows
  end

  def row_text(row)
    return "Players: #{@player_count}" if row == :game_size
    return "Play" if row == :play

    player_index = player_index_for_row(row)
    "Player #{player_index + 1}: #{display_type(@player_types[player_index])}"
  end

  def player_row?(row)
    [:player_one, :player_two, :player_three, :player_four].include?(row)
  end

  def player_index_for_row(row)
    return 0 if row == :player_one
    return 1 if row == :player_two
    return 2 if row == :player_three

    3
  end

  def cycle_player_count(delta)
    current_index = PLAYER_COUNT_OPTIONS.index(@player_count) || 0
    @player_count = PLAYER_COUNT_OPTIONS[(current_index + delta) % PLAYER_COUNT_OPTIONS.length]
    normalize_player_types!
  end

  def normalize_player_types!
    if @player_count == 2
      @player_types = @player_types.take(2)
    else
      @player_types = @player_types.take(4)
      while @player_types.length < 4
        @player_types << :human
      end
    end
  end

  def display_type(type)
    return "RandomBot" if type == :random_bot
    return "PathBot" if type == :path_bot
    return "LastLineBot" if type == :last_line_bot
    return "PressureBot" if type == :pressure_bot

    "Human"
  end

  def cycle_player_type(player_index, delta)
    return if player_index >= @player_types.length

    current_type = @player_types[player_index]
    current_index = PLAYER_TYPES.index(current_type) || 0
    @player_types[player_index] = PLAYER_TYPES[(current_index + delta) % PLAYER_TYPES.length]
  end

  def play_confirmed?(args)
    selected_row == :play && (confirm_pressed?(args) || mouse_clicked_row?(args, :play))
  end

  def selected_row
    rows = visible_rows
    rows[selected_row_index % rows.length]
  end

  def selected_row_index
    @selected_row_index ||= 0
  end

  def select_next_row
    @selected_row_index = (selected_row_index + 1) % visible_rows.length
  end

  def select_previous_row
    @selected_row_index = (selected_row_index - 1) % visible_rows.length
  end

  def hovered_row_index(args)
    mouse = args.inputs.mouse
    return nil unless mouse
    return nil if mouse.x.nil? || mouse.y.nil?

    visible_rows.each_with_index do |_row, index|
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

    visible_rows[index] == row
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
