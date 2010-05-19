me = File.dirname(__FILE__)
require 'nandoc/cli'
require me + '/commands/create-nandoc-site.rb'
require me + '/commands/diff.rb'
require me + '/commands/patch.rb'
require me + '/commands/view.rb'

base = Nanoc3::CLI::Base.shared_base

base.remove_command Nanoc3::CLI::Commands::CreateSite
base.add_command    NanDoc::CreateNanDocSite.new

base.add_command    NanDoc::Commands::Diff.new

base.add_command    NanDoc::Commands::Patch.new

base.remove_command Nanoc3::CLI::Commands::View
base.add_command    NanDoc::Commands::View.new
