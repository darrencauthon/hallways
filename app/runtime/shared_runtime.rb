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
end
