require File.dirname(__FILE__)+'/recordings.rb'

module NanDoc
  module SpecDoc
    module AgentInstanceMethods
      # share things between MockPrompt and TestCaseAgent

      # we used to use first method, now we use first test_ method
      def method_name_to_record caller
        line = caller.detect{ |x| x =~ /in `test_/ } or fail('hack fail')
        method = line =~ /in `(.+)'\Z/ && $1 or fail("hack fail")
        method
      end

      def recordings
        @recordings ||=  NanDoc::SpecDoc::Recordings.get(test_case)
      end

      def story story_name
        method = method_name_to_record(caller)
        rec = recordings
        rec.add(:method, method)
        rec.add(:story, story_name)
        nil
      end

    end

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
      # @todo maybe get rid of this.  we interpolate inspects elsewhere
      def ruby_string_raw
        @ruby_string_raw ||= begin
          these = all_lines[line_start..(line_stop-2)]
          these.join('') # they have newlines already
        end
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

    module ParseTrace
      #
      # @return [Regexp] enhanced regex that parses a stack trace line
      #
      def parse_trace
        @parse_trace_re ||= begin
          re = /\A(.*):(\d+)(?::in `([^']+)')?\Z/
          RegexpEnhance.names(re, :file, :line, :method)
          re
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
end
