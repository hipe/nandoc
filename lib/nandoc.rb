me = File.dirname(__FILE__)+'/nandoc'
require me + '/support-modules.rb'
require me + '/data-source.rb'
require me + '/create-nandoc-site.rb'
require me + '/item-class-hacks.rb'
require me + '/helpers.rb'

Nanoc3::DataSource.register ::NanDoc::DataSource, :nandoc
Nanoc3::CLI::Base.shared_base.add_command NanDoc::CreateNanDocSite.new

module NanDoc
  #
  # i make the D big so i can see it
  # i move my head away from the microphone when i breathe
  #

  Root = File.expand_path('../..',__FILE__)

  module Config
    extend self
    @orphan_surrogate_filename = Root + '/proto/misc/orphan-surrogate.md'
    attr_accessor :orphan_surrogate_filename
  end

end
