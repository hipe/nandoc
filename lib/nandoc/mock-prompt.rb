require File.dirname(__FILE__)+'/test/minitest-extlib.rb'

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

    # wrapper around FileUtils cd that takes block form
    # the tail portion of the path if any that you want to go documented
    # with SpecDoc is the second arg.  The first arg if any is the part
    # of the path that will go undocumented.
    def cd actual_basedir, specdoc_subdir=nil, &block
      actual_path = File.join( * [actual_basedir, specdoc_subdir].compact)
      if specdoc_subdir && @record
        @recordings.add(:cd, specdoc_subdir)
      end
      FileUtils.cd(actual_path) do
        block.call(self)
      end
      if specdoc_subdir && @record
        @recordings.add(:cd_end)
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

    def err string, opts={}
      exp = reindent string
      assert_equal_strings exp, @last_err, opts
    end

    def out string, opts={}
      exp = reindent(string)
      @record && @recordings.add(:out, exp)
      assert_equal_strings exp, @last_out, opts
    end

    def out_begin exp_begin
      @exp_begin = reindent(exp_begin)
      @record && @recordings.add(:out_begin, @exp_begin)
      # we don't do the assert until we get to (any?) end
    end

    def out_end exp_end, opts={}
      @exp_begin or fail("no begin found for end")
      exp_end2 = reindent(exp_end)
      @record && @recordings.add(:out_end, exp_end2)
      act_begin = @last_out[0..@exp_begin.length-1]
      assert_equal_strings @exp_begin, act_begin, opts
      act_end = @last_out[(exp_end2.length * -1)..-1]
      assert_equal_strings exp_end2, act_end, opts
    end

    def record story_name=nil
      require File.dirname(__FILE__)+'/spec-doc.rb'
      method = caller.first =~ /in `(.+)'\Z/ && $1 or fail("hack fail")
      @record = true
      @recordings = NanDoc::SpecDoc::Recordings.get @test_case
      @recordings.add(:method, method)
      @recordings.add(:story, story_name) if story_name
    end

    def record_stop
      @record = false
      @recordings = nil
    end

  private

    def assert_equal_strings exp, act, opts
      # @test_case.assert_equal exp, @last_out
      @test_case.assert_no_diff exp, act, nil, opts
    end

    # this is different than the dozens of similar ones
    def reindent str
      these = str.scan(/^[\t ]*/).each.with_index.map
      string, idx = these.min_by{ |x| x[0].length }
      if string.length == 0 && str.index("\n") # exp
        s2, _ =
          these.reject{ |x| x[0].length == 0 }.min_by{ |x| x[0].length }
        string = s2 if s2
      end
      re = /^#{Regexp.escape(string)}/
      str.gsub(re, '')
    end
  end
end
