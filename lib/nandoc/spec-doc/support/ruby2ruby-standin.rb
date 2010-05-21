module NanDoc::SpecDoc
  module Ruby2RubyStandin
    def leading_indent str
      /\A([ \t]*)/ =~ str && $1
    end
    def re_for_line_with_same_indent_as str
      ind = leading_indent(str)
      re = /\A#{Regexp.escape(ind)}(?=[^ \t])/
      re
    end
    def re_for_here here
      /\A[ \t]*#{Regexp.escape(here)}[ \t]*\n?\Z/
    end
    def re_for_unindent_gsub indent
      re = /\A#{Regexp.escape(indent)}/
      re
    end
    def reindent_content raw_content, indent
      return raw_content if indent == ''
      # of all non-blank lines find the minimum indent.
      x = raw_content.scan(/^[[:space:]]+(?=[^[:space:]])/).map(&:length).min
      # if for some reason the content has less indent than the fences,
      # don't alter any of it.
      return raw_content if x < indent.length
      re = /^#{Regexp.new(indent)}/
      unindented_content = raw_content.gsub(re, '')
      unindented_content
    end
    def string_diff_assert long, short
      idx = long.index(short) or fail("short not found in long -- "<<
      "#{short.inspect} in #{long.inspect}")
      head = long[0,idx] # usu. ''
      tail = long[idx + short.length..-1]
      head + tail
    end
  end
end
