module NanDoc::SpecDoc
  class TestCaseAgent
    include ParseTrace, AgentInstanceMethods, ::Treebis::Capture3
    def initialize test_case
      @test_case = test_case
    end

    # @param [block] gets called, and whatever is written to $stdout
    #   will get asserted against whatever is in
    # @param [String] exp.
    # if it passes (or fails?) one of the strings is written to an
    # :out node in the recording
    # raises something if $stderr is written to.
    #
    # warning - blah blah @todo
    #
    #
    def out exp, &block
      trace = parse_trace_assert(caller.first)
      out, err = capture3(&block)
      fail("no: #{err.inspect}") unless err == ""
      @test_case.assert_no_diff(exp, out)
      if out == exp
        recordings.add(:out, out, trace)
      end
      nil
    end
    def inspect mixed, exp_str = nil
      act_str = mixed.inspect
      line = caller.first
      trace = parse_trace_assert(line)
      if exp_str
        @test_case.assert_no_diff(exp_str, act_str, "at #{line}")
      end
      recordings.add(:inspect, act_str, trace)
    end
    def record_ruby
      md = parse_trace_assert(caller.first)
      snip = CodeSnippet.new(md)
      recordings.add(:method, snip.method)
      recordings.add(:record_ruby, snip)
      @last_snip = snip
      nil
    end
    def record_ruby_stop
      line = caller.first
      md = parse_trace_assert(caller.first)
      @last_snip or fail("no record_start in method before "<<
      "record_stop at #{line}")
      @last_snip.stop_at md
    end
  private
    def recordings
      Recordings.get(@test_case)
    end
  end
end
