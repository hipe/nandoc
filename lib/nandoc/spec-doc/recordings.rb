module NanDoc::SpecDoc

  class Recordings < Array
    #
    # everything that nandoc does during test runs gets written
    # to one of these.  It's like a Sexp structure.
    #

    @for_test_case = {}
    @for_key = {}

    class << self
      attr_accessor :for_test_case
      def get test_case
        @for_test_case[test_case.class] ||= new(test_case.class)
      end
      def get_for_key key
        @for_key[key] ||= new(key)
      end
      def report_test_case_not_found tc
        msgs = ["no recordings found for #{tc}"]
        msgs.join('  ')
      end
    end

    def add name, *data
      # this might change if we need to group by method name
      push [name, *data]
    end

    def get_first_sexp_for_test_method meth
      first = index([:method, meth]) or return nil
      last = (first+1..length-1).detect do |i|
        self[i].first == :method && self[i][1] != meth
      end
      last = last ? (last - 1) : (length - 1)
      ret = self[first..last]
      ret
    end

    def initialize test_case
      @test_case = test_case
    end

    def note &block
      push [:note, block]
    end

    def report_recording_not_found meth_name
      "no recordings found for #{meth_name}"
    end

    attr_reader :test_case
  end
end
