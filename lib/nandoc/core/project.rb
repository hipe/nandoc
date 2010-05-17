require 'singleton'
module NanDoc
  class Project
    #
    # manages figuring out where folders are for things like tests,
    # and builds test framework proxies for running tests
    #

    include Singleton
  private
    def initialize
    end
  public

    # not especially robust at all
    def project_root
      @project_root ||= begin
        presumed_root = File.dirname(FileUtils.pwd)
        thems = %w(spec test)
        found = thems.detect{ |dir| File.directory?(presumed_root+'/'+dir) }
        fail("couldn't find " <<
          StringMethods.oxford_comma(thems,' or ', &quoted) <<
          "in #{presumed_root}") unless found
        presumed_root
      end
    end

    def require_test_file testfile
      path = testdir + '/' + testfile
      fail("test file not found: #{path.inspect}") unless File.file?(path)
      require path
    end

    def testdir
      @testdir ||= begin
        tries = [project_root+'/test', project_root+'/spec']
        found = tries.detect{ |path| File.directory?(path) }
        fail("Couldn't find test dir for gem at (#{tries*', '})") unless found
        found
      end
    end

    def test_framework_proxy_for_file path
      @the_only_proxy ||= begin
        require 'nandoc/spec-doc/test-framework/mini-test/proxy'
        SpecDoc::TestFramework::MiniTest::Proxy.new
      end
    end
  end
end
