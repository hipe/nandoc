module NanDoc::Deployers
  class Rsync < ::Nanoc3::Extra::Deployers::Rsync
    #
    # just shows the command to $stdout before running it for debugging
    #

    def run_shell_cmd(args)
      $stdout.puts "rsync command: "
      $stdout.puts args.join(' ') # we should be shelljoining but whatever
      super(args)
    end
  end
end
