module NanDoc
  module Config
    extend self

    #
    # this name etc etc
    #

    @orphan_surrogate_filename = Root + '/proto/misc/orphan-surrogate.md'
    attr_accessor :orphan_surrogate_filename


    #
    # in the future make this smarter.  i don't like now nanoc handles color
    # (a command line argument?) There should be an autodetect, and/or set
    # last setting in sticky json file; or however it is it is done. @todo
    #
    def colorize?
      true
    end

    #
    # everybody wants to look like git
    #
    def diff_stylesheet
      @diff_stylesheet ||= {
        :header => [:bold, :yellow],
        :add    => [:bold, :green],
        :remove => [:bold, :red],
        :range  => [:bold, :magenta]
      }
    end

    #
    # some FileUtils actions are wrapped with this proxy to allow
    # formatting and customizations from the typical FileUtils actions,
    # to indent and colorize the notice stream sorta like nanoc does
    #

    def file_utils
      @file_utils ||= begin
        Treebis::FileUtilsProxy.new do |fu|
          fu.pretty!
          fu.color?{ NanDoc::Config.colorize? }
          fu.prefix = ' ' * 6 # like nanoc
          fu.ui = proc{ $stdout }
          # it's normally $stderr, it needs to be reference-like
          # so that capture3 will work!
        end
      end
    end

    #
    # Give some visual distinction of what options for a given command
    # are a nanDoc hack
    #
    def option_prefix_colorized
      "(\e[35mnanDoc\e[0m) "
    end

    def option_prefix_no_color
      '(nanDoc hack) '
    end

    def option_prefix
      colorize? ?
        option_prefix_colorized :
        option_prefix_no_color
    end

    #
    # other parts of the app include this module to get convenience methods
    # to some of the config nodes.
    #
    module Accessors
      def file_utils
        NanDoc::Config.file_utils
      end
    end
  end
end
