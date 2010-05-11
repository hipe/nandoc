# little hack to a) let clients just include this file for test runs
# and b) allow us to do the symlink hack for developing this.
unless Object.const_defined?('NanDoc')
  require File.expand_path('../../nandoc.rb', __FILE__)
end

me = File.dirname(__FILE__)+'/spec-doc'
require me + '/support-modules.rb'
require me + '/test-case-agent.rb'
require me + '/test-framework-dispatcher.rb'

module NanDoc
  module SpecDoc
    class << self

      #
      # enhance a test framework spec or test case module
      # for e.g. a minitest spec class.
      #
      def include_to mod
        if Object.const_defined?('MiniTest') &&
            mod.ancestors.include?(::MiniTest::Spec)
          require File.dirname(__FILE__)+'/spec-doc/mini-test.rb'
          ::NanDoc::SpecDoc::MiniTest::SpecInstanceMethods.include_to mod
        else
          fail("don't know how to enhance test module: #{mod}")
        end
      end
    end

    def initialize gem_root
      @sexp_cache = Hash.new{|h,k| h[k] = {}}
      @test_framework_dispatcher = TestFrameworkDispatcher.new(gem_root)
    end

    #
    # only run any test method at most once, just to keep recordings clean
    #
    def get_sexp testfile, testname
      sexp = @sexp_cache[testfile][testname] ||= begin
        @test_framework_dispatcher.get_sexp testfile, testname
      end
      sexp
    end
  end
end
