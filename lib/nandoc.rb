# this kind of sucks but for a wicked hack to work with symlinks
# we have to wrap this sucker.

unless Object.const_defined?('NanDoc')

  module NanDoc; end
  #
  # i make the D big so i can see it
  # i move my head away from the microphone when i breathe
  #


  require 'nanoc3'
  require 'nanoc3/cli'
  require 'treebis'
  me = File.dirname(__FILE__)+'/nandoc'
  require me + '/core/config.rb'
  require me + '/hacks.rb'
  require me + '/commands.rb'
  # only above should be necessary for 'create site'

  require me + '/helpers.rb'
  require me + '/filters.rb'
  require me + '/core/project.rb'
end
