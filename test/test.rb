require 'minitest/spec'
require File.expand_path('../../lib/nandoc.rb', __FILE__)

MiniTest::Unit.autorun

describe 'Basic' do
  Treebis::PersistentDotfile.include_to(self, '.nandoc.persistent.json')
  include Treebis::DirAsHash
  include Treebis::Sopen2

  def file_utils
    @fu ||= NanDoc::Config.file_utils
  end

  def prompt
    NanDoc::MockPrompt.new(self)
  end

  before do
    @pwd = tmpdir + '/foo'
    file_utils.remove_entry_secure @pwd
    basic_tree = {
      'README' => <<-HERE.gsub(/^ +/,'')
        # Hello
        ## Hi
        this is some stuff
        ruby:
        ~~~
        this is some code
        ~~~
      HERE
    }
    hash_to_dir basic_tree, @pwd, file_utils
  end

  it 'basic usage -- readme' do
    prompt.cd(@pwd) do |p|
      p.record
      p.enter2 'cat README'
      p.out <<-HERE
        # Hello
        ## Hi
        this is some stuff
        ruby:
        ~~~
        this is some code
        ~~~
      HERE
    end
  end

  it 'basic usage -- create site' do
    prompt.cd(@pwd) do |p|
      p.record
      p.enter2 'nandoc create_nandoc_site my-site'
      p.out_begin <<-HERE
        \e[1m\e[32m      create\e[0m  config.yaml
        \e[1m\e[32m      create\e[0m  Rakefile
        \e[1m\e[32m      create\e[0m  Rules
        \e[1m\e[32m      create\e[0m  content/index.html
      HERE
      p.cosmetic_ellipsis "      [...]"
      p.out_end <<-HERE
              \e[1;32mcp\e[0m ...oto/default/layouts/default.html layouts/default.html
              \e[1;32mcp\e[0m ...oto/default/lib/default.rb lib/default.rb
        Created a blank nanoc site at 'my-site'. Enjoy!
      HERE
      p.record_stop
      p.err ""
    end
  end

  it 'basic usage -- compile site' do

  end
end
