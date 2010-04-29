module NanDoc
  module Config
    extend self

    #
    # this name etc etc
    #

    @orphan_surrogate_filename = Root + '/proto/misc/orphan-surrogate.md'
    attr_accessor :orphan_surrogate_filename


    #
    # some FileUtils actions are wrapped with this proxy
    #

    def file_utils
      @file_utils ||= begin
        Treebis::FileUtilsProxy.new do |fu|
          fu.pretty! # @todo color should be dynamic ick
          fu.prefix = ' ' * 6 # like nanoc
          fu.ui = proc{ $stdout }
          # it's normally $stderr, it needs to be reference-like
          # so that capture3 will work!
        end
      end
    end
  end
end
