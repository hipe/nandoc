require 'stringio'
require 'minitest/unit'
require 'minitest/spec'

module NanDoc
  class SpecDoc

    class << self
      def include_to mod
        MiniTest::SpecInstanceMethods.include_to mod
      end
    end

    def initialize gem_root
      @gem_root = gem_root
      @setup = false
      @sexp_cache = Hash.new{|h,k| h[k] = {}}
    end

    #
    # only run any test method at most once, just to keep recordings clean
    #
    def get_sexp testfile, testname
      setup unless @setup
      sexp = @sexp_cache[testfile][testname] ||= begin
        load_file testfile
        test_case, meth_name = find_test testname
        unambig_re = /\A#{Regexp.escape(meth_name)}\Z/
        runner = ::MiniTest::Unit.new
        runner.instance_variable_set('@verbose', true)
        test_count, ass_count = runner.run_test_suites unambig_re
        fail("didn't run any tests for #{unambig_re.source}") unless
          test_count == 1
        if runner.report.any?
          handle_failed_tests(runner, testfile, testname) == 0 or return
        end
        recs = SpecDoc::Recordings.for_test_case[test_case] or
          fail SpecDoc::Recordings.report_test_case_not_found(test_case)
        sexp = recs.get_first_sexp_for_test_method(meth_name) or
          fail recs.report_recording_not_found(meth_name)
        sexp
      end
      sexp
    end

  private

    def find_test str
      meth_tail = str.gsub(/\W+/, '_').downcase
      # i *think* we want *not* to escape it below
      filter =  /\Atest_\d{4}_#{meth_tail}\Z/
      found_meths = []
      found_pairs = []
      ::MiniTest::Unit::TestCase.test_suites.each do |suite|
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
    def setup
      return if @setup
      @testout = StringIO.new
      ::MiniTest::Unit.output = @testout
        # this is set but ignored which is ok. it gets method names and dots
      sing = class << ::MiniTest::Unit; self end
      sing.send(:define_method, :autorun){ } # override it to do nothing!!
      @setup = true
    end
    def err
      $stderr
    end
    def testout_str
      @testout.rewind
      @testout.read
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
    module ParseTrace; end
    class CodeSnippet
      # internally this does deferred parsing of the thing

      def initialize matches_hash
        @start_at = matches_hash
        @stop_at = nil
      end
      attr_reader :start_at
      %w(method line file).each do |meth|
        sym = meth.to_sym
        define_method(meth){ || @start_at[sym] }
      end
      def describe
        last = method ? ":in `#{method}'" : ''
        "#{file}:#{line}#{tail}"
      end
      def file_lines
        @file_lines ||= begin
          stop_at_assert    # not really appropriate here
          same_file_assert  # not really appropriate here
          all_lines = File.open(@start_at[:file],'r').lines.map # sure why not
          all_lines
        end
      end
      def line_start
        @start_at[:line]
      end
      def line_stop
        @stop_at[:line]
      end
      # @todo maybe get rid of this.  we interpolate inspects elsewhere
      def ruby_string_raw
        @ruby_string_raw ||= begin
          these = all_lines[line_start..(line_stop-2)]
          these.join('') # they have newlines already
        end
      end
      def stop_at data=nil
        data ? (@stop_at = data) : @stop_at
      end
    private
      def same_file_assert
        @stop_at[:file] == @start_at[:file] or fail("I want life to be"<<
        " simple. start and stop files must be the same: "<<
        ([@stop_at, @start_at].map{ |x| File.basename(x)}*' and '))
      end
      def stop_at_assert
        stop_at or fail("no record_ruby_stop() found in method "<<
        "after #{describe}")
      end
    end
    # this will move one day
    module MiniTest
      module SpecInstanceMethods
        class << self
          def include_to mod
            unless mod.ancestors.include?(::MiniTest::Spec)
              fail(
               "Sorry, for now SpecDoc can only extend MiniTest::Spec "<<
               " tests.  Couldn't extend #{mod}."
              )
            end
            mod.send(:include, self)
          end
        end
        def nandoc
          @nandoc_agent ||= TestCaseAgent.new(self)
        end
      end
      class TestCaseAgent
        include ParseTrace
        def initialize test_case
          @test_case = test_case
        end
        def out exp, &block
          trace = parse_trace_assert(caller.first)
          prev = $stdout
          $stdout = StringIO.new
          captured = nil
          begin
            block.call
          ensure
            captured = $stdout
            $stdout = prev
          end
          captured.rewind
          act = captured.read
          @test_case.assert_no_diff(exp, act)
          recordings.add(:out, act, trace)
        end
        def inspect mixed, exp_str = nil
          act_str = mixed.inspect
          line = caller.first
          trace = parse_trace_assert(line)
          if exp_str
            @test_case.assert_no_diff(exp_str, act_str, "at #{line}")
          end
          recordings.add(:inspect, act_str, trace)
        end
        def record_ruby
          md = parse_trace_assert(caller.first)
          snip = CodeSnippet.new(md)
          recordings.add(:method, snip.method)
          recordings.add(:record_ruby, snip)
          @last_snip = snip
          nil
        end
        def record_ruby_stop
          line = caller.first
          md = parse_trace_assert(caller.first)
          @last_snip or fail("no record_start in method before "<<
          "record_stop at #{line}")
          @last_snip.stop_at md
        end
      private
        def recordings
          Recordings.get(@test_case)
        end
      end
    end
    module ParseTrace
      #
      # @return [Regexp] enhanced regex that parses a stack trace line
      #
      def parse_trace
        @parse_trace_re ||= begin
          re = /\A(.*):(\d+)(?::in `([^']+)')?\Z/
          RegexpEnhance.names(re, :file, :line, :method)
          re
        end
      end
      def parse_trace_assert line
        md = parse_trace.match(line) or
          fail("couldn't parse trace line: #{line}")
        h = md.to_hash
        /\A\d+\Z/ =~ h[:line] or fail("not line: #{h[:line]}.inspect")
        h[:line] = h[:line].to_i
        h
      end
    end
    class Recordings < Array
      @for_test_case = {}

      class << self
        attr_accessor :for_test_case
        def get test_case
          @for_test_case[test_case.class] ||= new(test_case.class)
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
end
