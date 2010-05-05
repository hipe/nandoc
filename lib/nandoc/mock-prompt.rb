module NanDoc
  class MockPrompt
    #
    # This is a bit of a misnomer.  it's actually just a wrapper
    # around the real shell.  It's for testing.  SpecDoc.
    #

    include Treebis::Sopen2

    def initialize test_case=nil
      @last_both = @last_out = @last_err = nil
      @test_case = test_case
    end

    def cd dir, &block
      FileUtils.cd(dir) do
        block.call(self)
      end
    end

    def enter2 cmd
      @last_both = nil
      @last_out, @last_err = sopen2(cmd)
    end

    def err string
      exp = reindent(string)
      @test_case.assert_equal exp, @last_err
    end

    def out string
      exp = reindent(string)
      @test_case.assert_equal exp, @last_out
    end

  private

    def reindent str
      first = /\A([\t ]+)/ =~ str && $1
      re = /^#{Regexp.escape(first)}/
      str.gsub(re, '')
    end
  end
end
