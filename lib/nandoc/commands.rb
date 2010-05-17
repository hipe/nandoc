me = File.dirname(__FILE__)
require 'nandoc/cli'
require me + '/commands/create-nandoc-site.rb'
require me + '/commands/diff.rb'

shared_base = Nanoc3::CLI::Base.shared_base
shared_base.remove_command Nanoc3::CLI::Commands::CreateSite
shared_base.add_command    NanDoc::CreateNanDocSite.new
shared_base.add_command    NanDoc::Commands::Diff.new
