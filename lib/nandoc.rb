me = File.dirname(__FILE__)+'/nandoc'
require me + '/data-source.rb'
require me + '/create-nandoc-site.rb'

Nanoc3::DataSource.register ::NanDoc::DataSource, :nandoc
Nanoc3::CLI::Base.shared_base.add_command NanDoc::CreateNanDocSite.new

module NanDoc # i make the D big so i can see it
              # i move my head away from the microphone when i breathe

  Root = File.expand_path('../..',__FILE__)
end
