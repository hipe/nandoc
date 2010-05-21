module NanDoc::SpecDoc::Playback
  class Method
    # "playback" a recorded ruby (test?) method, generating html

    @handlers = {
      :cd          => [:class, 'Terminal', :run_cd],
      :cd_end      => [:class, 'Terminal', :run_cd_end],
      :command     => [:class, 'Terminal', :run_command],
      :note        => [:class, self, :run_note],
      :out         => [:class, 'Terminal', :run_out],
      :out_begin   => [:class, 'Terminal', :run_out_begin],
      :record_ruby => [:class, 'Ruby', :run_record_ruby],
      :story       => [:stop]
    }
    class << self
      attr_reader :handlers
    end

    include PlaybackMethods

  private
    def initialize test_file_path=nil, things=nil
      @test_file_path = test_file_path
      @things = things
    end
    def handlers
      Method.handlers
    end
  public
    def make_html doc
      fail("need one or two things") unless (1..2).include?(@things.size)
      fail("can't run method tag filter without at @test_file_path") unless
        @test_file_path
      proj = NanDoc::Project.instance
      proxy = proj.test_framework_proxy_for_file(@test_file_path)
      sexp = proxy.sexp_get @test_file_path, @things.first
      run_method_sexp(doc, sexp, *@things[1..-1])
      nil
    end
    def run_method_sexp doc, sexp, story=nil
      scn = SexpScanner.new(sexp)
      scn.scan_assert(:method)
      scn.skip_to_after_assert(:story, story) if story
      run_scanner doc, scn
    end
    def run_note out, scn
      node = scn.scan_assert(:note)
      note_content = node[1].call
      out.push_raw note_content
      nil
    end
    def run_scanner doc, scn
      node = scn.current or begin
        fail("unexpected end of sexp")
      end
      run_sexp_with_handlers(doc, scn)
      if ! scn.eos?
        node = scn.current
        if :method != node.first
          fail("#{self.class} has no handler for #{node.first.inspect}")
        end
      end
      nil
    end
    def run_sexp doc, sexp
      scn = SexpScanner.new(sexp)
      run_scanner doc, scn
    end
  end
end
