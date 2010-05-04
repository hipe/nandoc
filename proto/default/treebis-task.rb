# This is a treebis patch file for this folder and its contents.
# it is intended to be applied to a default nanoc site, and will
# mostly likely break whenever that changes.  See the README sibling
# to the folder containing this file.

Treebis.tasks.task(:default) do
  # opts[:patch_hack] = true
  remove  './content/index.html' # assume we will use README.md for now.
                                 # we don't want multiple '/' @items.
  # apply   './Rules.diff'
  # apply   './config.yaml.diff'
  # apply   './content/stylesheet.css.diff'
  # move    './content/stylesheet.css', 'content/css/nanoc-dist-altered.css'
  # apply   './layouts/default.html.diff'
  # apply   './lib/default.rb.diff'
  copy    './Rules'
  copy    './Rakefile'
  copy    './config.yaml'
  mkdir_p './content/css/'
  remove  './content/stylesheet.css'
  copy    './content/css/*.css'
  mkdir_p './content/js/'
  copy    './content/js/*.js'
  mkdir_p './content/vendor/'
  copy    './content/vendor/*.js'
  copy    './layouts/default.html'
  copy    './lib/default.rb'
end
