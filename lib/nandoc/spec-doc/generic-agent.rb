module NanDoc::SpecDoc
  class GenericAgent
    #
    # Experimental doohickey that lets random ass objects record
    # things.
    #

    include ParseTrace
    
    def initialize whatever
      @whatever = whatever
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

  private
    def recordings
      Recordings.get_for_key(:generic)
    end
  end
end
