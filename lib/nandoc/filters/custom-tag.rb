require 'strscan'

module NanDoc::Filters
  class CustomTag
    # include TagParsingInstanceMethods
    def initialize
    end
    def name
      @name || 'anonymous custom filter'
    end
    def tag_parser
      nil
    end
    private :tag_parser
    def wants? md
      tp = tag_parser
      ret = nil
      if ! tp
        ret = false
        @last_failure_lines = ["#{name} doesn't want #{md[:content].inspect}"]
      else
        if tree = tp.parse(md[:content])
          ret = true
          @last_tree = tree
        else
          ret = false
          these = tp.failure_lines(md[:content])
          these.unshift("#{name} couldn't parse tag:")
          @last_failure_lines = these
        end
      end
      ret
    end
    def get_failure_lines md
      @last_failure_lines
    end
    def render_block filter, md
      fail("this is the one you want to implement. look at @last_tree maybe.")
    end
  end
end
