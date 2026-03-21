require "app/models/player_palette.rb"
require "app/renderers/player_box_renderer.rb"

class SetupScreen
  PLAYER_TYPES = [:human, :random_bot, :path_bot, :last_line_bot, :pressure_bot].freeze
  PLAYER_COUNT_OPTIONS = [2, 4].freeze
  MENU_X_CENTER = 640
  HEADER_X = 60
  GAME_SIZE_Y = 610
  PLAY_X_CENTER = 1080
  PLAY_Y = 360
  MAIN_MENU_Y = 300
  MENU_HOVER_HALF_HEIGHT = 24
  MENU_HOVER_X_PADDING = 280
  PLAYER_BOX_GAP_X = 80
  PLAYER_BOX_GAP_Y = 26
  PLAYER_BOX_LEFT_X = 60
  PLAYER_BOX_RIGHT_X = PLAYER_BOX_LEFT_X + PlayerBoxRenderer.box_width + PLAYER_BOX_GAP_X
  PLAYER_BOX_TOP_Y = 350
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
      x: 60,
      y: 670,
      text: "Game Setup",
      alignment_enum: 0,
      size_enum: 5,
      r: 240,
      g: 240,
      b: 240
    }

    render_menu_rows(args)
    render_player_boxes(args)
    return [:start_game, { player_count: @player_count, player_types: @player_types.dup }] if play_confirmed?(args)
    return :main_menu if main_menu_confirmed?(args)

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
      x = row == :game_size ? HEADER_X : (action_row?(row) ? PLAY_X_CENTER : MENU_X_CENTER)
      args.outputs.labels << {
        x: x,
        y: row_y(index),
        text: selected ? "> #{text} <" : text,
        alignment_enum: row == :game_size ? 0 : 1,
        size_enum: action_row?(row) ? 5 : 3,
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
    rows << :main_menu
    rows
  end

  def row_text(row)
    return "Players: #{@player_count}" if row == :game_size
    return "Start Game" if row == :play
    return "Main Menu" if row == :main_menu

    player_index = player_index_for_row(row)
    "Player #{player_index + 1}: #{display_type(@player_types[player_index])}"
  end

  def action_row?(row)
    [:play, :main_menu].include?(row)
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

  def main_menu_confirmed?(args)
    selected_row == :main_menu && (confirm_pressed?(args) || mouse_clicked_row?(args, :main_menu))
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
      center_x = row == :game_size ? (HEADER_X + 110) : (action_row?(row) ? PLAY_X_CENTER : MENU_X_CENTER)
      if mouse.x >= (center_x - MENU_HOVER_X_PADDING) &&
         mouse.x <= (center_x + MENU_HOVER_X_PADDING) &&
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
    player_box_renderer.render(
      args,
      x: rect[:x],
      y: rect[:y],
      fill_color: player_box_fill_for(player_index),
      selected: selected,
      title: "< #{display_type(player_type)} >",
      title_size_enum: 2,
      title_color: PLAYER_BOX_TEXT_COLOR,
      subtitle: "Player #{player_index + 1}",
      subtitle_size_enum: 1,
      subtitle_color: PLAYER_BOX_LABEL_COLOR
    )
  end

  def player_box_rect(player_index)
    row_y = if player_index == 0 || player_index == 2
              PLAYER_BOX_TOP_Y
            else
              PLAYER_BOX_TOP_Y - player_box_height - PLAYER_BOX_GAP_Y
            end

    {
      x: player_index == 0 || player_index == 1 ? PLAYER_BOX_LEFT_X : PLAYER_BOX_RIGHT_X,
      y: row_y,
      w: PlayerBoxRenderer.box_width,
      h: player_box_height
    }
  end

  def player_box_height
    PlayerBoxRenderer.box_height
  end

  def player_box_fill_for(player_index)
    PlayerPalette::BOX_FILLS[player_index] || PlayerPalette::BOX_FILLS[0]
  end

  def mouse_inside_rect?(mouse, rect)
    mouse.x >= rect[:x] &&
      mouse.x <= rect[:x] + rect[:w] &&
      mouse.y >= rect[:y] &&
      mouse.y <= rect[:y] + rect[:h]
  end

  def row_y(index)
    row = visible_rows[index]
    return GAME_SIZE_Y if row == :game_size
    return PLAY_Y if row == :play
    return MAIN_MENU_Y if row == :main_menu

    player_box_rect(player_index_for_row(row))[:y] + 32
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

  def player_box_renderer
    @player_box_renderer ||= PlayerBoxRenderer.new
  end
end
