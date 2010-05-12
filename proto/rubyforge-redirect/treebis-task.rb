# This is a treebis patch file for this folder and its contents.
# See the README sibling to the folder containing this file.

Treebis.tasks.task(:"rubyforge-redirect") do
  prop    :lay_over_nanoc_site?, false
  copy    './Rakefile'
  erb     './config.yaml'
  mkdir_p './output/'
  erb     './output/index.html'
end
