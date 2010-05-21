module NanDoc::SpecDoc
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
end
