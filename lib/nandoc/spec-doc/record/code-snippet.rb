module NanDoc::SpecDoc
  class CodeSnippet
    #
    # internally this does deferred parsing of the thing
    # a code snippet holds meta information (or maybe content)
    # for record_ruby nandoc commands in tests.
    #

    def initialize matches_hash
      @start_at = matches_hash
      @stop_at = nil
      @lines_proc = nil
    end
    attr_reader :start_at
    %w(method line file).each do |meth|
      sym = meth.to_sym
      define_method(meth){ || @start_at[sym] }
    end
    def describe
      last = method ? ":in `#{method}'" : ''
      "#{file}:#{line}#{tail}"
    end
    # just hide all the lines from dumps to make irb debugging prettier
    def file_lines
      @lines_proc ||= begin
        stop_at_assert    # not really appropriate here
        same_file_assert  # not really appropriate here
        all_lines = File.open(@start_at[:file],'r').lines.map # sure why not
        proc{ all_lines }
      end
      @lines_proc.call
    end
    def line_start
      @start_at[:line]
    end
    def line_stop
      @stop_at[:line]
    end
    def lines_raw
      @lines_raw ||= file_lines[line_start..(line_stop-2)]
    end
    def string_raw
      @string_raw ||= lines_raw.join('')
    end
    def stop_at data=nil
      data ? (@stop_at = data) : @stop_at
    end
  private
    def same_file_assert
      @stop_at[:file] == @start_at[:file] or fail("I want life to be"<<
      " simple. start and stop files must be the same: "<<
      ([@stop_at, @start_at].map{ |x| File.basename(x)}*' and '))
    end
    def stop_at_assert
      stop_at or fail("no record_ruby_stop() found in method "<<
      "after #{describe}")
    end
  end
end
