me = File.dirname(__FILE__)
require me + '/fence-dispatcher.rb'
require me +'/fence/terminal.rb'
NanDoc::Filters::FenceDispatcher.register NanDoc::Filters::Fence::Terminal
