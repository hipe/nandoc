module NanDoc::SpecDoc
  class TestCaseAgent
    include ParseTrace
    def initialize test_case
      @test_case = test_case
    end
    def out exp, &block
      trace = parse_trace_assert(caller.first)
      prev = $stdout
      $stdout = StringIO.new
      captured = nil
      begin
        block.call
      ensure
        captured = $stdout
        $stdout = prev
      end
      captured.rewind
      act = captured.read
      @test_case.assert_no_diff(exp, act)
      recordings.add(:out, act, trace)
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
