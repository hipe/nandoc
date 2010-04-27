# This is a treebis patch file for this folder and its contents.
# it is intended to be applied to a default nanoc site, and will
# mostly likely break whenever that changes.  See the README sibling
# to the folder containing this file.

Treebis.tasks.task(:default) do
  opts[:patch_hack] = true
  remove  './content/index.html' # assume we will use README.md for now.
                                 # we don't want multiple '/' @items.
  apply   './Rules.diff'
  apply   './config.yaml.diff'
  apply   './content/stylesheet.css.diff'
  mkdir_p './content/css/'
  move    './content/stylesheet.css', 'content/css/nanoc-dist-altered.css'
  copy    './content/css/trollop-subset.css'
  apply   './layouts/default.html.diff'
  apply   './lib/default.rb.diff'
end
