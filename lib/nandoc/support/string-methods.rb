module NanDoc
  # @dependencies: none

  module StringMethods
    def basename_no_extension str
      /([^\/\.]+)(?:\.[^\.\/]+)?\Z/ =~ str ? $1 : nil
    end
    def indent str, indent
      str.gsub(/^/, indent)
    end
    def no_blank_lines str
      str.gsub(/\n[[:space:]]*\n/, "\n")
    end
    def no_leading_ws str
      str.sub(/\A[[:space:]]+/, '')
    end
    def no_trailing_ws str
      str.sub(/[[:space:]]+\Z/, '')
    end
    def oxford_comma items, final = ' and ', &quoter
      items = items.map(&quoter) if quoter
      these = []
      these.push final if items.size > 1
      these.concat(Array.new(items.size-2,', ')) if items.size > 2
      these.reverse!
      items.zip(these).flatten.compact.join
    end
    module_function :oxford_comma
    def quoted
      proc{|x| "\"#{x}\"" }
    end

    #
    # must respond to tab() and tabs()
    # reindent a block by striping leading whitespace from lines evenly
    # and then re-indenting each line according to our indent.
    # this could be simpler, it has been more complicated
    # we do it languidly because we can
    #
    def reindent h1, offset=0
      indent_by = tab * (tabs+offset)
      unindent_by = (/\A([[:space:]]+)/ =~ h1 && $1) or
        fail('regex fail -- not sure if we need this to be so strict')
      h2 = no_blank_lines(h1) # careful. will mess up with <pre> etc
      return h2 if unindent_by == indent_by
      h3 = unindent(h2, unindent_by)
      h4 = indent(h3, indent_by)
      h4
    end

    def unindent str, by=nil
      by ||= (/\A([ \t]*)/ =~ str and $1 )
      str.gsub(/^#{Regexp.escape(by)}/, '')
    end
  end
end
