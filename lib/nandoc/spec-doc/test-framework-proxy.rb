module NanDoc::SpecDoc
  class TestFrameworkProxy
    # abstract baseclass, an agent that runs tests

    def initialize gem_root
      @gem_root = gem_root
    end

    def get_sexp testfile, testname
      TestFrameworkProxy.sexp_cache[testfile][testname] ||= begin
        build_sexp testfile, testname
      end
    end

    def build_sexp testfile, testname
      load_file testfile
      test_case, meth_name = find_test testname
      run_test_case_method testfile, testname, test_case, meth_name
      recs = ::NanDoc::SpecDoc::Recordings.for_test_case[test_case] or
        fail(::NanDoc::SpecDoc::Recordings.
                               report_test_case_not_found(test_case))
      sexp = recs.get_first_sexp_for_test_method(meth_name) or
        fail recs.report_recording_not_found(meth_name)
      sexp
    end

    @sexp_cache = Hash.new{ |h,k| h[k] = {} }
    class << self
      attr_reader :sexp_cache
    end

  protected

    #
    # the stream to write to when things like a specdoc test run fails
    #
    def err
      $stderr
    end

    def handle_failed_tests runner, testfile, testname
      err.print "can't SpecDoc. at least one test failed when trying to run"
      err.puts " #{testfile.inspect} #{testname.inspect} - "
      runner.report.each do |line|
        err.puts line
      end
      err.puts "Please get your tests green and re-run."
      exit(1);
    end

    def load_file testfile
      path = testdir + '/' + testfile
      fail("test file not found: #{path.inspect}") unless File.file?(path)
      # if you need to, do a diff
      require path
    end

    #
    # default way to read what the test run wrote to stdout
    #
    def testout_str
      @testout.rewind
      @testout.read
    end

    #
    # default way to deduce the root directory that holds the tests
    #
    def testdir
      @testdir ||= begin
        tries = [@gem_root+'/test', @gem_root+'/spec']
        found = tries.detect{ |path| File.directory?(path) }
        fail("Couldn't find test dir for gem at (#{tries*', '})") unless found
        found
      end
    end
  end
end
