module NanDoc
  class MockPrompt
    #
    # This is a bit of a misnomer.  it's actually just a wrapper
    # around the real shell.  It's for testing.  SpecDoc.
    #

    include Treebis::Sopen2

    def initialize test_case=nil
      @last_both = @last_out = @last_err = nil
      @record = false
      @test_case = test_case
    end

    def cd dir, &block
      FileUtils.cd(dir) do
        block.call(self)
      end
    end

    def cosmetic_ellipsis str
      @record && @recordings.add(:cosmetic_ellipsis, str)
    end

    def enter2 cmd
      @last_both = nil
      @record && @recordings.add(:command, cmd)
      @last_out, @last_err = sopen2(cmd)
    end

    def err string
      exp = reindent string
      @test_case.assert_equal exp, @last_err
    end

    def out string
      exp = reindent(string)
      @record && @recordings.add(:out, exp)
      @test_case.assert_equal exp, @last_out
    end

    def out_begin exp_begin
      @exp_begin = reindent(exp_begin)
      @record && @recordings.add(:out_begin, @exp_begin)
      # we don't do the assert until we get to (any?) end
    end

    def out_end exp_end
      @exp_begin or fail("no begin found for end")
      exp_end2 = reindent(exp_end)
      @record && @recordings.add(:out_end, exp_end2)
      act_begin = @last_out[0..@exp_begin.length-1]
      @test_case.assert_equal @exp_begin, act_begin
      act_end = @last_out[(exp_end2.length * -1)..-1]
      @test_case.assert_equal exp_end2, act_end
    end

    # maybe take block one day
    def record
      method = caller.first =~ /in `(.+)'\Z/ && $1 or fail("hack fail")
      @record = true
      require File.dirname(__FILE__)+'/spec-doc.rb'
      @recordings = NanDoc::SpecDoc::Recordings.get @test_case
      @recordings.add(:method, method)
    end

    def record_stop
      @record = false
      @recordings = nil
    end

  private

    # this is different than the dozens of similar ones
    def reindent str
      these = str.scan(/^[\t ]*/)
      string, len = these.each.with_index.map.min_by{ |x| x[0].length }
      re = /^#{Regexp.escape(string)}/
      str.gsub(re, '')
    end
  end
end
