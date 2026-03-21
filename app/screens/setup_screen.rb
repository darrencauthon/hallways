require "app/models/player_palette.rb"

class SetupScreen
  PLAYER_TYPES = [:human, :random_bot, :path_bot, :last_line_bot, :pressure_bot].freeze
  PLAYER_COUNT_OPTIONS = [2, 4].freeze
  MENU_X_CENTER = 640
  MENU_Y_START = 520
  MENU_Y_STEP = 50
  MENU_HOVER_HALF_HEIGHT = 24
  MENU_HOVER_X_PADDING = 280
  PLAYER_BOX_W = 220
  PLAYER_BOX_LEFT_X = 120
  PLAYER_BOX_RIGHT_X = 940
  PLAYER_BOX_TOP_Y = 360
  PLAYER_BOX_BOTTOM_Y = 80
  PLAYER_BOX_AVATAR_MARGIN_X = 12
  PLAYER_BOX_AVATAR_MARGIN_TOP = 10
  PLAYER_BOX_AVATAR_SCALE = 0.72
  PLAYER_BOX_NAME_GAP = 14
  PLAYER_BOX_TEXT_GAP = 8
  PLAYER_BOX_BOTTOM_PADDING = 14
  PLAYER_BOX_BORDER = { r: 88, g: 94, b: 110 }.freeze
  PLAYER_BOX_ACTIVE_BORDER = { r: 255, g: 215, b: 120 }.freeze
  PLAYER_BOX_AVATAR_FILL = { r: 16, g: 18, b: 22 }.freeze
  PLAYER_BOX_LABEL_COLOR = { r: 170, g: 176, b: 190 }.freeze
  PLAYER_BOX_TEXT_COLOR = { r: 235, g: 235, b: 235 }.freeze

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

    render_menu_rows(args)
    render_player_boxes(args)
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

  def render_menu_rows(args)
    visible_rows.each_with_index do |row, index|
      next if player_row?(row)

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

  def render_player_boxes(args)
    visible_rows.each_with_index do |row, index|
      next unless player_row?(row)

      player_index = player_index_for_row(row)
      rect = player_box_rect(player_index)
      render_player_box(
        args,
        rect: rect,
        selected: index == selected_row_index,
        player_index: player_index,
        player_type: @player_types[player_index]
      )
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

    visible_rows.each_with_index do |row, index|
      if player_row?(row)
        rect = player_box_rect(player_index_for_row(row))
        if mouse_inside_rect?(mouse, rect)
          return index
        end
        next
      end

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

  def render_player_box(args, rect:, selected:, player_index:, player_type:)
    border_color = selected ? PLAYER_BOX_ACTIVE_BORDER : PLAYER_BOX_BORDER
    avatar_size = ((PLAYER_BOX_W - (PLAYER_BOX_AVATAR_MARGIN_X * 2)) * PLAYER_BOX_AVATAR_SCALE).to_i
    avatar_x = rect[:x] + PLAYER_BOX_AVATAR_MARGIN_X
    avatar_y = rect[:y] + rect[:h] - PLAYER_BOX_AVATAR_MARGIN_TOP - avatar_size
    selector_y = avatar_y - PLAYER_BOX_NAME_GAP
    label_y = selector_y - PLAYER_BOX_TEXT_GAP - 14

    args.outputs.solids << {
      x: rect[:x],
      y: rect[:y],
      w: rect[:w],
      h: rect[:h],
      **player_box_fill_for(player_index)
    }

    args.outputs.solids << {
      x: avatar_x,
      y: avatar_y,
      w: avatar_size,
      h: avatar_size,
      **PLAYER_BOX_AVATAR_FILL
    }

    args.outputs.borders << {
      x: rect[:x],
      y: rect[:y],
      w: rect[:w],
      h: rect[:h],
      **border_color
    }

    args.outputs.borders << {
      x: avatar_x,
      y: avatar_y,
      w: avatar_size,
      h: avatar_size,
      **border_color
    }

    render_placeholder_player_sprite(args, x: avatar_x, y: avatar_y, w: avatar_size, h: avatar_size, color: border_color)

    args.outputs.labels << {
      x: rect[:x] + 14,
      y: selector_y,
      text: display_type(player_type),
      alignment_enum: 0,
      size_enum: 2,
      **PLAYER_BOX_TEXT_COLOR
    }

    args.outputs.labels << {
      x: rect[:x] + 14,
      y: label_y,
      text: "Player #{player_index + 1}",
      alignment_enum: 0,
      size_enum: 1,
      **PLAYER_BOX_LABEL_COLOR
    }
  end

  def player_box_rect(player_index)
    {
      x: player_index == 0 || player_index == 2 ? PLAYER_BOX_LEFT_X : PLAYER_BOX_RIGHT_X,
      y: player_index == 0 || player_index == 3 ? PLAYER_BOX_TOP_Y : PLAYER_BOX_BOTTOM_Y,
      w: PLAYER_BOX_W,
      h: player_box_height
    }
  end

  def player_box_height
    avatar_size = ((PLAYER_BOX_W - (PLAYER_BOX_AVATAR_MARGIN_X * 2)) * PLAYER_BOX_AVATAR_SCALE).to_i
    PLAYER_BOX_AVATAR_MARGIN_TOP + avatar_size + PLAYER_BOX_NAME_GAP + 14 + PLAYER_BOX_TEXT_GAP + 14 + PLAYER_BOX_BOTTOM_PADDING
  end

  def player_box_fill_for(player_index)
    PlayerPalette::BOX_FILLS[player_index] || PlayerPalette::BOX_FILLS[0]
  end

  def render_placeholder_player_sprite(args, x:, y:, w:, h:, color:)
    line_count = 8
    thickness = 3
    step_x = ((w - thickness).to_f / (line_count - 1))
    step_y = ((h - thickness).to_f / (line_count - 1))

    line_count.times do |index|
      offset_x = (index * step_x).to_i
      offset_y = (index * step_y).to_i
      args.outputs.solids << {
        x: x + offset_x,
        y: y + offset_y,
        w: thickness,
        h: thickness,
        **color
      }
      args.outputs.solids << {
        x: x + w - thickness - offset_x,
        y: y + offset_y,
        w: thickness,
        h: thickness,
        **color
      }
    end
  end

  def mouse_inside_rect?(mouse, rect)
    mouse.x >= rect[:x] &&
      mouse.x <= rect[:x] + rect[:w] &&
      mouse.y >= rect[:y] &&
      mouse.y <= rect[:y] + rect[:h]
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
