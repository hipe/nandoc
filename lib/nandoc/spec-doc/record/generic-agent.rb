module NanDoc::SpecDoc
  class GenericAgent
    #
    # Experimental spec agent that is not tied to any test case or framework
    #

    include ParseTrace

    def initialize whatever
      @whatever = whatever
    end

    class << self
      def custom_spec_hook name, &block
        define_method name, &block
      end
    end

    def record_ruby
      caller_info = parse_trace_assert(caller.first)
      snip = CodeSnippet.new(caller_info)
      recordings.add(:record_ruby, snip)
      @last_snip = snip
      nil
    end

    def record_ruby_stop
      line = caller.first
      caller_info = parse_trace_assert(line)
      @last_snip or fail("no record_start in method before "<<
      "record_stop at #{line}")
      @last_snip.stop_at caller_info
    end

    # override the one that requires we are in a method
    def story name
      recordings.add :story, name
    end

    def story_stop
      recordings.add :story_stop
    end

    # only call this if u know what u are doing
    def recordings
      Recordings.get_for_key(:generic)
    end
  end
end
