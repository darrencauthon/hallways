module SharedRuntime
  def self.command_line_args(args)
    if args.gtk.respond_to?(:argv) && args.gtk.argv
      args.gtk.argv
    elsif args.gtk.respond_to?(:cli_arguments) && args.gtk.cli_arguments
      args.gtk.cli_arguments
    else
      []
    end
  end

  def self.request_quit(args)
    if args.gtk.respond_to? :request_quit
      args.gtk.request_quit
    elsif $gtk && $gtk.respond_to?(:request_quit)
      $gtk.request_quit
    end
  end

  def self.toggle_fullscreen_if_requested(args)
    return unless fullscreen_toggle_pressed?(args)

    if args.gtk.respond_to?(:toggle_window_fullscreen)
      args.gtk.toggle_window_fullscreen
      return
    end

    if args.gtk.respond_to?(:window_fullscreen?) && args.gtk.respond_to?(:set_window_fullscreen)
      args.gtk.set_window_fullscreen(!args.gtk.window_fullscreen?)
      return
    end

    if $gtk && $gtk.respond_to?(:toggle_window_fullscreen)
      $gtk.toggle_window_fullscreen
    end
  end

  def self.fullscreen_toggle_pressed?(args)
    keyboard = args.inputs&.keyboard
    return false if keyboard.nil?
    return false if keyboard.key_down.nil?

    !!keyboard.key_down.f
  end
end
