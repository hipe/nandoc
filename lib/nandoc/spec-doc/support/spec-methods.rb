
#
# These are the methods that will be available to nandoc-enhanced tests.
# For now it is recommended to leave this as just the one method nandoc(),
# which will return the TestCaseAgent.
#
module NanDoc::SpecDoc::SpecMethods
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
    @nandoc_agent ||= NanDoc::SpecDoc::TestCaseAgent.new(self)
  end
end

#
# Experimental nandoc hook to give random ass objects a hook to some
# kind of SpecDoc agent thing that can a) not necessarily be a test case
# but b) still write recordings somehow.  let's see what happens.  hook.
#
module NanDoc::SpecDoc::SpecMethodsGeneric
  class << self
    def include_to mod
      mod.send(:include, self)
    end
  end
  def nandoc
    @nandoc_agent ||= begin
      NanDoc::SpecDoc::GenericAgent.new(self)
    end
  end
end
