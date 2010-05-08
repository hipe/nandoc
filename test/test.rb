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
        This::Is(:some => 'ruby'){ |x| x.code! }
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
        This::Is(:some => 'ruby'){ |x| x.code! }
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
      p.record 'compile site'
      p.cd(@pwd,'my-site') do
        p.enter2 'nandoc compile'
        p.out((
        <<-HERE
        Loading site data...
        Compiling site...
        \e[1m\e[32m      create\e[0m  [0.00s]  output/vendor/jquery.easing.1.3.js
        \e[1m\e[32m      create\e[0m  [0.00s]  output/css/trollop-subset.css
        \e[1m\e[32m      create\e[0m  [0.00s]  output/vendor/jquery-1.3.js
        \e[1m\e[32m      create\e[0m  [0.00s]  output/js/menu-bouncy.js
        \e[1m\e[32m      create\e[0m  [0.00s]  output/css/nanoc-dist-altered.css
        \e[1m\e[32m      create\e[0m  [0.16s]  output/index.html

        Site compiled in 0.17s.
        HERE
        ), :ignoring => /\d\.\d\ds/ )
      end
      weird_nokogiri_stuff(@pwd+'/my-site', p)
    end
  end
  def weird_nokogiri_stuff path, prompt
    require 'nokogiri'
    path = path + '/output/index.html'
    doc = Nokogiri::HTML::Document.parse(File.read(path))
    body_content = doc.xpath('//body').first.inner_html
    assert_match(/this is some stuff/, body_content)
    prompt.record 'index page body'
    prompt.note{ body_content }
  end
end
