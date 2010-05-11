require 'stringio'
require File.expand_path('../../test/minitest-extlib.rb', __FILE__)

module NanDoc::SpecDoc::MiniTest
  class Proxy < ::NanDoc::SpecDoc::TestFrameworkProxy

    def initialize(*a)
      super(*a)
      @hacked_minitest = false
    end

  private

    #
    # given
    # @param [String] the natural sounding string name as it appears in
    #   documentation,
    # @return [Array] a pair of strings: suite name and method name
    #
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

    #
    # do whatever you have to do to prepare minitest to run nandoc-enabled
    # tests
    #
    def hack_minitest
      return if @hacked_minitest
      @testout = StringIO.new
      ::MiniTest::Unit.output = @testout
        # this is set but ignored which is ok. it gets method names and dots
      sing = class << ::MiniTest::Unit; self end
      sing.send(:define_method, :autorun){ } # override it to do nothing!!
      @hacked_minitest = true
    end

    #
    # given
    # @param [String] testfile name (just semantic not formal)
    # @param [String] testname (just semantic not formal)
    # @param [String] a test case name and
    # @param [String] a method name,
    # run the test in question which will hopefully write to the recordings
    # experimentally
    # @return an exit status of 0 if everything's ok
    #
    def run_test_case_method testfile, testname, test_case, meth_name
      hack_minitest unless @hacked_minitest
      unambig_re = /\A#{Regexp.escape(meth_name)}\Z/
      runner = ::MiniTest::Unit.new
      runner.instance_variable_set('@verbose', true)
      test_count, ass_count = runner.run_test_suites unambig_re
      fail("didn't run any tests for #{unambig_re.source}") unless
        test_count == 1
      if runner.report.any?
        return handle_failed_tests(runner, testfile, testname)
      end
      return 0
    end
  end


  #
  # These are the methods that will be available to nandoc-enhanced tests.
  # For now it is recommended to leave this as just the one method nandoc(),
  # which will return the TestCaseAgent.
  #
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
      @nandoc_agent ||= ::NanDoc::SpecDoc::TestCaseAgent.new(self)
    end
  end
end
