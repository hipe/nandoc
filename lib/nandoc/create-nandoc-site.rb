require File.dirname(__FILE__)+'/treebis/lib/treebis.rb'

module NanDoc
  class CreateNanDocSite < ::Nanoc3::CLI::Commands::CreateSite
    include OptsNormalizer, TaskCommon
    #
    # Most of this is fluff/filler.  The key is that 1)
    # in run() we set the datasource to be NanDoc::DataSource and 2)
    # after the parent's site_populate() is run we apply our patch to it.
    #

    def name; 'create_nandoc_site' end

    def aliases; [ 'cnds', 'cns' ] end

    def short_desc; 'create a nandoc site' end

    def long_desc
      'Create a new site at the given path. This builds on the ' +
      'create_site nandoc command.  Please see that for more '+
      'information.  Run this next to your README.md file.'
    end

    def usage; "nandoc create_nandoc_site <path>" end

    def option_definitions
      [ { :long => 'patch-hack', :short => 'p', :argument => :none,
          :desc => 'tell treebis to use files not patches when necessary'
      } ]
    end

    def run options, arguments
      normalize_opts options
      if options[:datasource]
        task_abort <<-ABO.gsub(/\n */,"\n").trim
        for now datasource is hardcoded to be nandoc.
        usage: #{usage}
        ABO
      end
      options[:datasource] = 'nandoc'
      @patch_hack = options[:patch_hack]
      super(options, arguments)
    end

  protected

    #
    # see SupremeStderrHack
    #
    def initiate_the_supreme_hack_of_the_standard_error_stream
      base = Nanoc3::CLI::Base
      return if base.instance_methods.include?("print_error_orig")
      base.send(:alias_method, :print_error_orig, :print_error)
      base.send(:define_method, :print_error) do |error|
        $stderr = SupremeStderrHack.new($stderr)
        print_error_orig error
      end
    end

    #
    # This is the crux of the whole thing: make the site as the parent
    # does, then apply the patch.
    #
    def site_populate
      initiate_the_supreme_hack_of_the_standard_error_stream
      super
      Treebis.dir_task(NanDoc::Root+'/proto/default').on(FileUtils.pwd).run(
        :patch_hack => @patch_hack
      )
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
            @ui.puts <<-HERE.gsub(/^ +/,'')
           +--- /!\ ERROR /!\ --------------------------------------------+
           | An exception occured while running nandoc. If you think this |
           | is a bug in nandoc (likely), please report it at             |
           | <http://github.com/hipe/nandoc/issues> -- thanks!            |
           | (it is very likely a treebis patch failure)                  |
           +--------------------------------------------------------------+
           HERE
          else
            @ui.puts(*a) # probably just whitespace?
          end
        when :waiting_for_end_of_error_box
          if a.first && a.first =~ /\+-+\+/
            $stderr = @ui
            @state = :hack_failed # nothing should be callig our puts() method any more
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
