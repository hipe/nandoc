module NanDoc
  class CreateNanDocSite < ::Nanoc3::CLI::Commands::CreateSite
    #
    # Most of this is fluff/filler/hacks.  The key is that 1)
    # in run() we set the datasource to be NanDoc::DataSource and 2)
    # after the parent's site_populate() is run we apply our patch to it.
    #


    include Cli::CommandMethods
    include Cli::OptionMethods

    def name; 'create_nandoc_site' end

    def aliases; [ 'cnds', 'cns', 'cs' ] end # override create_site short!

    def short_desc
      "#{NanDoc::Config.option_prefix}create a nandoc site"
    end

    def long_desc
      prefix = NanDoc::Config.option_prefix
      <<-D.gsub(/\n +/,' ')
      #{prefix}Create a new site at the given path. This builds on the
      create_site nanoc3 command.  Please see that for more
      information.  Run this next to your README.md file.
      D
    end

    def usage; "nandoc create_nandoc_site [-m] <path>" end

    def option_definitions
      @opt_defs ||= begin
        prefix = NanDoc::Config.option_prefix
        [
          { :long => 'patch-hack', :short => 'p', :argument => :none,
            :desc => "#{prefix} use files not patches when necessary" },

          { :long => 'merge-hack', :short => 'm', :argument => :none,
            :desc =>
              "#{prefix}when site already exists do something clever"
          },
          { :long => 'merge-hack-reverse', :short => 'M', :argument => :none,
            :desc =>
              "#{prefix}show the reverse diff of above."
          },
          { :long => 'prototype', :short=>'t', :argument => :required,
            :default => 'default',
            :desc => "#{prefix}the name of the site prototype to use"
          }
        ]
      end
    end

    #
    # On the _merge option: when we are doing a merge with a generated
    # site and we want to generate a fresh site, we want to turn the below
    # stderr hack off.
    #
    def run(opts, args, method_opts={:_merge=>true})
      args = store_extra_args(args)
      opts = normalize_opts opts
      run_opts_process opts

      return prototype_run_without_nanoc(args) unless
        @treebis_task.lay_over_nanoc_site?

      #
      # awful: see if nanoc triggers the error message about site
      # already existing, then take action
      #
      if method_opts[:_merge]
        StdErrListener.new do |listener|
          listener.when(/A site at '.*' already exists/) do
            throw :nandoc_hack, :site_already_exists
          end
        end
      end
      ret = nil
      thing = catch(:nandoc_hack) do
        ret = super(opts, args)
        :normal
      end
      case thing
      when :site_already_exists
        site_already_exists opts, args
      when :normal
        ret
      else
        fail("hack fail: #{thing.inspect}")
      end
    end

    def run_opts_process opts

      # not sure where to put this
      initiate_the_supreme_hack_of_the_standard_error_stream

      command_abort("you can't have both -M and -m") if
        opts[:merge_hack] && opts[:merge_hack_reverse]
      if opts[:datasource]
        command_abort <<-ABO.gsub(/\n */,"\n").strip
        for now datasource is hardcoded to be nandoc.
        usage: #{usage}
        ABO
      end
      opts[:datasource] = 'nandoc'
      @patch_hack = opts[:patch_hack]
      prototype_determine opts
      nil
    end
    private :run_opts_process

  protected

    def err *a
      $stderr.puts(*a)
    end

    #
    # see SupremeStderrHack
    #
    def initiate_the_supreme_hack_of_the_standard_error_stream
      return if @extremely_hacked
      base = Nanoc3::CLI::Base
      return if base.instance_methods.include?("print_error_orig")
      base.send(:alias_method, :print_error_orig, :print_error)
      base.send(:define_method, :print_error) do |error|
        $stderr = SupremeStderrHack.new($stderr)
        print_error_orig error
      end
      @extremely_hacked = true
    end

    def prototype_determine opts
      proto_name = opts[:prototype] || 'default'
      require 'nandoc/support/treebis-extlib' # experimental
      proto_path = "#{Config.proto_path}/#{proto_name}"
      @treebis_task = Treebis.dir_task(proto_path)
    end

    def prototype_run
      task = @treebis_task
      names = task.erb_variable_names
      if names.any?
        require 'nandoc/erb/agent'
        Erb::Agent.process_erb_values_from_the_commandline(
          self, task, names, @extra_args
        )
      end
      task.file_utils = Config.file_utils
      task.on(FileUtils.pwd).run(:patch_hack => @patch_hack)
    end

    def prototype_run_without_nanoc args
      if args.empty?
        err "missing <path> argument."
        err usage
        command_abort
      end
      if args.size > 1
        err "Too many arguments"
        err usage
        command_abort
      end
      path = args.first
      if File.exist?(path) && Dir[path+'/*'].any?
        err "folder already exists (no merge yet): #{path}"
        err usage
        command_abort
      end
      if ! File.exist?(path)
        fu = Config.file_utils
        fu.mkdir_p(path)
      end
      FileUtils.cd(path) do
        prototype_run
      end
    end

    def site_already_exists opts, args
      path = args.first
      if ! (opts[:merge_hack] || opts[:merge_hack_reverse])
        command_abort <<-FOO.gsub(/^ +/,'').chop
          A site at '#{path}' already exists.
          If you want to try and merge in changes from the site generator
          (this might just generate a diff), try the --merge-hack (-m) option.
          see `#{invocation_name} help #{name}` for more information
        FOO
      else
        require File.expand_path('../../support/site-merge.rb', __FILE__)
        SiteMerge.new(self).site_merge(opts, args)
      end
    end

    def store_extra_args args
      @extra_args = nil
      if args.length > 1 && args[1] =~ /^-/
        @extra_args = args[1..-1]
        args = args[0..0]
      end
      args
    end

    #
    # This is the crux of the whole thing: make the site as the parent
    # does, then apply the patch.
    #
    def site_populate
      initiate_the_supreme_hack_of_the_standard_error_stream
      super
      prototype_run
    end

    #
    # Somehow legitimize these awful hacks with an entire class
    #
    class StdErrListener
      def initialize &block
        @prev = $stderr
        $stderr = self
        @expired = false
        @whens = []
        block.call(self)
      end
      def when regex, &block
        @whens.push(:regex=>regex, :block=>block)
      end
      def puts *args
        if @expired
          fail("hack failed when trying to write: #{str}")
        elsif args.size != 1
          expire!
          $stderr.puts(*args)
        else
          found = @whens.detect{|x| x[:regex] =~ args.first}
          if found
            expire!
            found[:block].call
          else
            expire!
            $stderr.puts(*args)
          end
        end
      end
      alias_method :write, :puts # supreme & problematic
    private
      def expire!
        $stderr = @prev
        @expired = true
      end
    end


    class SupremeStderrHack
      #
      # ridiculous: make a state machine that rewrites part of the error
      # message coming from nanoc, then gets rid of itself when it's done.
      # This is so fragile and stupid but I really needed to get the nanoc
      # message ("please file bug reports") out of the error message so ppl
      # don't misfile bug reports there that are actually NanDoc bugs.
      #

      def initialize real
        @ui = real
        @state = :looking_for_error_header
      end
      def puts *a
        case @state
        when :looking_for_error_header
          if a.first && a.first.include?('/!\ ERROR /!\\')
            @state = :waiting_for_end_of_error_box
            me = NanDoc::Config.option_prefix
            @ui.puts <<-HERE.gsub(/^ +/,'')
        +--- /!\\ ERROR /!\\ ----------------------------------------------+
        | An exception occured while running #{me}. If you think     |
        | this is a bug in nanDoc (likely), please report it at          |
        | <http://github.com/hipe/nandoc/issues> -- thanks!              |
        | (it is very likely a treebis patch failure)                    |
        +----------------------------------------------------------------+
           HERE
          else
            @ui.puts(*a) # probably just whitespace?
          end
        when :waiting_for_end_of_error_box
          if a.first && a.first =~ /\+-+\+/
            $stderr = @ui
            @state = :hack_failed
              # nothing should be callig our puts() method any more
          end
        when :hack_failed
          fail("hack failed")
        else
          fail("huh?")
        end
      end
      def write *a
        @ui.write(*a)
      end
    end
  end
end
