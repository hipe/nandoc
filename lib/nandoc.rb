require 'nanoc3'
require 'nanoc3/cli'

module NanDoc
  #
  # i make the D big so i can see it
  # i move my head away from the microphone when i breathe
  #
  Root = File.expand_path('../..',__FILE__)
end

me = File.dirname(__FILE__)+'/nandoc'

# order is important:
require me + '/support-modules.rb'
require me + '/treebis/lib/treebis.rb'
require me + '/config.rb'

module NanDoc
  Treebis::PersistentDotfile.extend_to(self,
    './nandoc.persistent.json',
    :file_utils => Config.file_utils
  )
end

# order is not important: (alphabetical:)
require me + '/commands/create-nandoc-site.rb'
require me + '/commands/diff.rb'
require me + '/cri-hacks.rb'
require me + '/data-source.rb'
require me + '/filters.rb'
require me + '/helpers.rb'
require me + '/item-class-hacks.rb'
require me + '/mock-prompt.rb'

Nanoc3::DataSource.register ::NanDoc::DataSource, :nandoc
Nanoc3::Filter.register ::NanDoc::Filters::General, :nandoc

shared_base = Nanoc3::CLI::Base.shared_base
shared_base.remove_command Nanoc3::CLI::Commands::CreateSite
shared_base.add_command    NanDoc::CreateNanDocSite.new
shared_base.add_command    NanDoc::Commands::Diff.new
