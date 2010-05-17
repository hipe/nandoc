me = File.dirname(__FILE__)+'/hacks'
require me + '/cri-hacks.rb'
require me + '/item-class-hacks.rb'
require me + '/data-source.rb'

Nanoc3::DataSource.register ::NanDoc::DataSource, :nandoc
