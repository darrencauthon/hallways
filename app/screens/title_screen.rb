class TitleScreen
  BASE_MENU_OPTIONS = ["New Game", "Quit"].freeze
  MENU_X_CENTER = 640
  MENU_Y_START = 250
  MENU_Y_STEP = 45
  MENU_HOVER_HALF_HEIGHT = 24
  MENU_HOVER_X_PADDING = 220
  BACKGROUND_GRID_CELL_SIZE = 48
  BACKGROUND_GRID_CELL_GAP = 6
  BACKGROUND_GRID_ALPHA = 64

  def initialize(can_continue_game: false)
    @can_continue_game = can_continue_game
  end

  def tick(args)
    handle_input(args)

    args.outputs.background_color = [20, 20, 28]
    render_board_pattern_background(args)
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
      text: "A DragonRuby implementation of Quoridor",
      alignment_enum: 1,
      size_enum: 2,
      r: 180,
      g: 180,
      b: 190
    }

    render_menu(args)
    render_version(args)

    confirmed = confirm_pressed?(args) || mouse_click_confirm?(args)
    return :continue_game if confirmed && selected_option == "Continue Game"
    return :open_setup if confirmed && selected_option == "New Game"
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
    menu_options.each_with_index do |option, index|
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

  def render_version(args)
    args.outputs.labels << {
      x: screen_width(args) - 10,
      y: 28,
      text: "v#{game_version}",
      alignment_enum: 2,
      size_enum: 1,
      r: 140,
      g: 140,
      b: 150
    }
  end

  def select_next
    @selected_index = (selected_index + 1) % menu_options.length
  end

  def select_previous
    @selected_index = (selected_index - 1) % menu_options.length
  end

  def selected_index
    @selected_index ||= 0
  end

  def selected_option
    menu_options[selected_index]
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

    menu_options.each_with_index do |_option, index|
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

  def menu_options
    return ["Continue Game"] + BASE_MENU_OPTIONS if @can_continue_game

    BASE_MENU_OPTIONS
  end

  def mouse_click_confirm?(args)
    mouse = args.inputs.mouse
    return false unless mouse

    !!mouse.down && !hovered_menu_index(args).nil?
  end

  def screen_width(args)
    return args.grid.w if args.respond_to?(:grid) && args.grid && args.grid.respond_to?(:w)

    1280
  end

  def screen_height(args)
    return args.grid.h if args.respond_to?(:grid) && args.grid && args.grid.respond_to?(:h)

    720
  end

  def render_board_pattern_background(args)
    step = BACKGROUND_GRID_CELL_SIZE + BACKGROUND_GRID_CELL_GAP
    y = 0
    row = 0
    while y < screen_height(args)
      x = 0
      col = 0
      while x < screen_width(args)
        shade = ((row + col).even? ? 72 : 56)
        args.outputs.solids << {
          x: x,
          y: y,
          w: BACKGROUND_GRID_CELL_SIZE,
          h: BACKGROUND_GRID_CELL_SIZE,
          r: shade,
          g: shade,
          b: shade + 12,
          a: BACKGROUND_GRID_ALPHA
        }
        x += step
        col += 1
      end
      y += step
      row += 1
    end
  end

  def game_version
    version = version_from_metadata
    return version unless version.nil? || version.empty?

    "0.1.9"
  end

  def version_from_metadata
    metadata_path = metadata_file_path
    return nil if metadata_path.nil?

    line = read_metadata_lines(metadata_path).find { |entry| entry.start_with?("version=") }
    return nil if line.nil?

    line.split("=", 2)[1]&.strip
  rescue StandardError
    nil
  end

  def metadata_file_path
    candidates = [
      "metadata/game_metadata.txt",
      "hallways/metadata/game_metadata.txt",
      File.expand_path("../../metadata/game_metadata.txt", File.dirname(__FILE__))
    ]

    candidates.find { |path| File.exist?(path) }
  rescue StandardError
    nil
  end

  def read_metadata_lines(metadata_path)
    File.read(metadata_path).split("\n")
  end
end
