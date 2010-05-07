require 'stringio'
require 'minitest/unit'
require 'minitest/spec'

module NanDoc
  class SpecDoc
    def initialize gem_root
      @gem_root = gem_root
      @setup = false
    end
    def get_sexp testfile, testname
      setup unless @setup
      load_file testfile
      test_case, meth_name = find_test testname
      unambig_re = /\A#{Regexp.escape(meth_name)}\Z/
      runner = MiniTest::Unit.new
      runner.instance_variable_set('@verbose', true)
      test_count, ass_count = runner.run_test_suites unambig_re
      fail("didn't run any tests for #{unambig_re.source}") unless
        test_count == 1
      recs = SpecDoc::Recordings.for_test_case[test_case] or
        fail("no recordings found for #{test_case}")
      sexp = recs.get_first_sexp_for_test_method(meth_name) or
        fail("no recordings found for #{meth_name}")
      sexp
    end
  private
    def find_test str
      meth_tail = str.gsub(/\W+/, '_').downcase
      # i *think* we want *not* to escape it below
      filter =  /\Atest_\d{4}_#{meth_tail}\Z/
      found_meths = []
      found_pairs = []
      MiniTest::Unit::TestCase.test_suites.each do |suite|
        if (foundfound = suite.test_methods.grep(filter)).any?
          found_pairs.push [suite, foundfound]
          found_meths.concat foundfound
        end
      end
      case found_meths.size
      when 0;
        fail("no tests were found whose name matches the pattern #{filter}")
      when 1;
        ff = found_pairs.first
        [ff[0], ff[1][0]] # suite and method name
      else
        fail("found more than one test matching the pattern for \"#{str}\""<<
        " -- (#{found_meths.join(', ')})")
      end
    end
    def load_file testfile
      path = testdir + '/' + testfile
      fail("test file not found: #{path.inspect}") unless File.file?(path)
      # if you need to, do a diff
      require path
    end
    def setup
      return if @setup
      @testout = StringIO.new
      MiniTest::Unit.output = @testout
        # this is set but ignored which is ok. it gets method names and dots
      sing = class << MiniTest::Unit; self end
      sing.send(:define_method, :autorun){ } # override it to do nothing!!
      @setup = true
    end
    def testdir
      @testdir ||= begin
        tries = [@gem_root+'/test', @gem_root+'/spec']
        found = tries.detect{ |path| File.directory?(path) }
        fail("Couldn't find test dir for gem at (#{tries*', '})") unless found
        found
      end
    end
  public
    class Recordings < Array
      @for_test_case = {}

      class << self
        attr_accessor :for_test_case
        def get test_case
          @for_test_case[test_case.class] ||= new(test_case.class)
        end
      end

      def add name, data
        # this might change if we need to group by method name
        push [name, data]
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

      attr_reader :test_case
    end
  end
end
