require File.dirname(__FILE__)+'/test-framework-proxy.rb'

module NanDoc
  module SpecDoc
    class TestFrameworkDispatcher
      def initialize gem_root
        require File.dirname(__FILE__)+'/mini-test.rb'
        @the_only_proxy = SpecDoc::MiniTest::Proxy.new(gem_root)
      end
      def get_sexp *a
        @the_only_proxy.get_sexp(*a)
      end
    end
  end
end
