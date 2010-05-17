module NanDoc::Filters

  me = File.dirname(__FILE__) + '/builtin-tags'

  require me + '/see-test'
  CustomTags.register_class SeeTest

  require me + '/fences'
  CustomTags.register_class FenceDispatcher

end
