require 'nandoc/support/regexp'

module NanDoc::SpecDoc
  module ParseTrace
    #
    # @return [Regexp] enhanced regex that parses a stack trace line
    #
    def parse_trace
      @parse_trace_re ||= begin
        NanDoc::Regexp.new(
          /\A(.*):(\d+)(?::in `([^']+)')?\Z/,
          :file, :line, :method
        )
      end
    end
    def parse_trace_assert line
      md = parse_trace.match(line) or
        fail("couldn't parse trace line: #{line}")
      h = md.to_hash
      /\A\d+\Z/ =~ h[:line] or fail("not line: #{h[:line]}.inspect")
      h[:line] = h[:line].to_i
      h
    end
  end
end
