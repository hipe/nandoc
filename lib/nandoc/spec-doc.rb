unless Object.const_defined?('NanDoc')
  # little hack to a) let clients just include this file for test runs
  # and b) allow us to do the symlink hack for developing this.
  #

  require File.expand_path('../../nandoc.rb', __FILE__)
end

# @todo get this right
unless NanDoc.const_defined?('SpecDoc') # TO_HERE_HACK

module NanDoc::SpecDoc
end

me = File.dirname(__FILE__)+'/spec-doc'
require me + '/support.rb'
require me + '/record.rb'
require me + '/playback.rb'
require me + '/test-framework.rb'

module NanDoc::SpecDoc
  class << self
    include NanDoc::StringMethods # fileize

    #
    # enhance a test framework spec or test case module
    # for e.g. a minitest spec class.
    #
    def include_to mod
      if Object.const_defined?('MiniTest') &&
          mod.ancestors.include?(::MiniTest::Spec)
        require 'nandoc/extlib/minitest.rb'
        SpecMethods.include_to mod
      else
        SpecMethodsGeneric.include_to mod
      end
    end

    def new_test_framework_proxy name
      if ! TestFramework.const_defined?(name)
        dirname = fileize(name)
        path = "nandoc/spec-doc/test-framework/#{dirname}"
        require path
      end
      proxy_class = TestFramework.const_get(name).const_get('Proxy')
      thing = proxy_class.new
      thing
    end

    #
    # no reason not to use the conventional callback
    # in cases where we are not passing parameters to the enhancement
    #
    alias_method :included, :include_to
  end
end

end # TO_HERE_HACK
