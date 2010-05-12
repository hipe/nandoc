# copy-paste-altered from nanoc3

require 'nandoc'
require 'rake'

module NanDoc::Tasks
  Prefix = "\e[35mnanDoc\e[0m " # @todo etc
end

# Dir[File.dirname(__FILE__) + '/tasks/**/*.rb'].each   { |f| load f }
Dir[File.dirname(__FILE__) + '/tasks/**/*.rake'].each { |f| Rake.application.add_import(f) }
