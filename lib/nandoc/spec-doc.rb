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
          SpecInstanceMethods.include_to mod
        else
          GenericInstanceMethods.include_to mod
        end
      end

      #
      # no reason not to use the conventional callback
      # in cases where we are not passing parameters to the enhancement
      #
      alias_method :included, :include_to
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


    #
    # Experimental nandoc hook to give random ass objects a hook to some
    # kind of SpecDoc agent thing that can a) not necessarily be a test case
    # but b) still write recordings somehow.  let's see what happens.  hook.
    #
    module GenericInstanceMethods
      class << self
        def include_to mod
          mod.send(:include, self)
        end
      end
      def nandoc
        @nandoc_agent ||= begin
          require File.dirname(__FILE__)+'/spec-doc/generic-agent'
          GenericAgent.new(self)
        end
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
          #
          # This used to be MiniTest::Spec-specific, now it's not, but here
          # for reference:
          #
          # unless mod.ancestors.include?(::MiniTest::Spec)
          #   fail(
          #    "Sorry, for now SpecDoc can only extend MiniTest::Spec "<<
          #    " tests.  Couldn't extend #{mod}."
          #   )
          # end
          mod.send(:include, self)
        end
      end
      def nandoc
        @nandoc_agent ||= TestCaseAgent.new(self)
      end
    end
  end
end
