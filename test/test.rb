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

  # test_0001_will_foo_and_bar
  it "will foo and bar" do
    prompt.cd(@pwd) do |p|
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
end
