require File.expand_path('../lib/nandoc/parse-readme.rb', __FILE__)

task :default => :test

me = "\e[35mnandoc\e[0m "

require 'jeweler'
Jeweler::Tasks.new do |s|
  s.authors = ['Chip Malice']
  s.description = NanDoc::ParseReadme.description('README')
  s.email = 'chip.malice@gmail.com'
  s.executables = ['nandoc']
  s.files =  FileList['Rakefile', '[A-Z]*(?:\.md)?', '{bin,doc,lib,test,proto}/**/*']
  s.homepage = 'http://nandoc.hipeland.org'
  s.name = 'nandoc'
  s.rubyforge_project = 'nandoc'
  s.summary = NanDoc::ParseReadme.summary('README')

  s.add_dependency 'nanoc3', '~> 3.1.2'
  s.add_dependency 'treebis', '~> 0.0.2'
  s.add_dependency 'syntax', '~> 1.0.0'
end


desc "#{me}hack turns the installed gem into a symlink to this directory"
task :hack do
  kill_path = %x{gem which nandoc}
  kill_path = File.dirname(File.dirname(kill_path))
  new_name  = File.dirname(kill_path)+'/ok-to-erase-'+File.basename(kill_path)
  FileUtils.mv(kill_path, new_name, :verbose => 1)
  this_path = File.dirname(__FILE__)
  FileUtils.ln_s(this_path, kill_path, :verbose => 1)
end

desc "#{me}generate rcov coverage"
task :rcov do
  sh %!rcov --exclude '.*gem.*' test/test.rb -- --seed 0!
end

desc "#{me}run the test file"
task :test do
  sh %!ruby -w -e 'require "test/test.rb"'!
end

# desc "#{me}remove temporary, generated files like coverage"
# task :prune do
#   require File.dirname(__FILE__)+'/lib/nandoc.rb'
#   file_utils = NanDoc::Config.file_utils
#   these = ['./lib/nandoc/treebis/coverage']
#   these.each do |this|
#     file_utils.remove_entry_secure(this, :verbose=>true)
#   end
# end
