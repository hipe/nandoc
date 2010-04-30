require 'rake/gempackagetask.rb'

spec = Gem::Specification.new do |s|
  s.name = "nandoc"
  s.version = '0.0.0'
  s.date = Time.now.to_s
  s.email = "chip.malice@gmail.com"
  s.authors = ["Chip Malice"]
  s.summary = "hack nanoc to turn your README into a sitelette"
  # s.homepage = "http://nandoc.rubyforge.org"
  s.files = %w(
    lib/nandoc.rb
    ) + Dir["*.md"]
  s.executables = ['nandoc']
  # s.rubyforge_project = "nandoc"
  s.description = <<-HERE
    make a static site from your README file(s) to document your gem
  HERE
end

Rake::GemPackageTask.new(spec){}

desc "hack turns the installed gem into a symlink to this directory"
task :hack do
  kill_path = %x{gem which nandoc}
  kill_path = File.dirname(File.dirname(kill_path))
  new_name  = File.dirname(kill_path)+'/ok-to-erase-'+File.basename(kill_path)
  FileUtils.mv(kill_path, new_name, :verbose => 1)
  this_path = File.dirname(__FILE__)
  FileUtils.ln_s(this_path, kill_path, :verbose => 1)
end

desc "remove temporary, generated files like coverage"
task :prune do
  require File.dirname(__FILE__)+'/lib/nandoc.rb'
  file_utils = NanDoc::Config.file_utils
  these = ['./lib/nandoc/treebis/coverage']
  these.each do |this|
    file_utils.remove_entry_secure(this, :verbose=>true)
  end
end
