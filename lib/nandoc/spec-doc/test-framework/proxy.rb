module NanDoc::SpecDoc::TestFramework
  class Proxy
  protected
    # abstract baseclass, an agent that runs tests

    @sexp_cache = Hash.new{ |h,k| h[k] = {} }
    class << self
      attr_reader :sexp_cache
    end

    def initialize
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

    # the stream to write to when things like a specdoc test run fails
    def err
      $stderr
    end

    def sexp_build testfile, testname
      NanDoc::Project.instance.require_test_file(testfile)
      test_case, meth_name = find_test testname
      run_test_case_method testfile, testname, test_case, meth_name
      recs = ::NanDoc::SpecDoc::Recordings.for_test_case[test_case] or
        fail(::NanDoc::SpecDoc::Recordings.
                               report_test_case_not_found(test_case))
      sexp = recs.get_first_sexp_for_test_method(meth_name) or
        fail recs.report_recording_not_found(meth_name)
      sexp
    end

  public
    def sexp_get testfile, testname
      Proxy.sexp_cache[testfile][testname] ||= begin
        sexp_build testfile, testname
      end
    end

  protected
    # default way to read what the test run wrote to stdout
    def testout_str
      @testout.rewind
      @testout.read
    end
  end
end
