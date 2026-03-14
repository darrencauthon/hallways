class TitleScreen
  MENU_OPTIONS = ["Start", "Quit"].freeze

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

    return :start if confirm_pressed?(args) && selected_option == "Start"
    return :quit if confirm_pressed?(args) && selected_option == "Quit"

    nil
  end

  private

  def handle_input(args)
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
        x: 640,
        y: 250 - (index * 45),
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
end
