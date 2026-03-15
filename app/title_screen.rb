class TitleScreen
  MENU_OPTIONS = ["Human vs Human", "Human vs Computer", "Quit"].freeze
  MENU_X_CENTER = 640
  MENU_Y_START = 250
  MENU_Y_STEP = 45
  MENU_HOVER_HALF_HEIGHT = 24
  MENU_HOVER_X_PADDING = 220

  def tick(args)
    handle_input(args)

    args.outputs.background_color = [20, 20, 28]
    args.outputs.labels << {
      x: 640,
      y: 380,
      text: "Hallways",
      alignment_enum: 1,
      size_enum: 6,
      r: 240,
      g: 240,
      b: 240
    }

    args.outputs.labels << {
      x: 640,
      y: 330,
      text: "DragonRuby + Quoridor prototype",
      alignment_enum: 1,
      size_enum: 2,
      r: 180,
      g: 180,
      b: 190
    }

    render_menu(args)

    confirmed = confirm_pressed?(args) || mouse_click_confirm?(args)
    return :start_human_vs_human if confirmed && selected_option == "Human vs Human"
    return :start_human_vs_computer if confirmed && selected_option == "Human vs Computer"
    return :quit if confirmed && selected_option == "Quit"

    nil
  end

  private

  def handle_input(args)
    hovered_index = hovered_menu_index(args)
    @selected_index = hovered_index unless hovered_index.nil?

    if up_pressed?(args)
      select_previous
    elsif down_pressed?(args)
      select_next
    end
  end

  def render_menu(args)
    MENU_OPTIONS.each_with_index do |option, index|
      selected = index == selected_index
      args.outputs.labels << {
        x: MENU_X_CENTER,
        y: menu_option_y(index),
        text: selected ? "> #{option} <" : option,
        alignment_enum: 1,
        size_enum: 4,
        r: selected ? 255 : 170,
        g: selected ? 220 : 170,
        b: selected ? 90 : 170
      }
    end
  end

  def select_next
    @selected_index = (selected_index + 1) % MENU_OPTIONS.length
  end

  def select_previous
    @selected_index = (selected_index - 1) % MENU_OPTIONS.length
  end

  def selected_index
    @selected_index ||= 0
  end

  def selected_option
    MENU_OPTIONS[selected_index]
  end

  def up_pressed?(args)
    args.inputs.keyboard.key_down.up
  end

  def down_pressed?(args)
    args.inputs.keyboard.key_down.down
  end

  def confirm_pressed?(args)
    args.inputs.keyboard.key_down.enter
  end

  def hovered_menu_index(args)
    mouse = args.inputs.mouse
    return nil unless mouse
    return nil if mouse.x.nil? || mouse.y.nil?

    MENU_OPTIONS.each_with_index do |_option, index|
      option_y = menu_option_y(index)
      if mouse.x >= (MENU_X_CENTER - MENU_HOVER_X_PADDING) &&
         mouse.x <= (MENU_X_CENTER + MENU_HOVER_X_PADDING) &&
         mouse.y >= (option_y - MENU_HOVER_HALF_HEIGHT) &&
         mouse.y <= (option_y + MENU_HOVER_HALF_HEIGHT)
        return index
      end
    end

    nil
  end

  def menu_option_y(index)
    MENU_Y_START - (index * MENU_Y_STEP)
  end

  def mouse_click_confirm?(args)
    mouse = args.inputs.mouse
    return false unless mouse

    !!mouse.down && !hovered_menu_index(args).nil?
  end
end
