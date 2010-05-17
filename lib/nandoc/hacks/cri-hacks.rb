require 'nandoc/cli'

module Cri
  class Base
    include NanDoc::Cli::CommandMethods
    def remove_command command_class
      if idx = @commands.index{|x| x.kind_of?(command_class) }
        @commands.delete_at(idx)
      else
        command_abort("command not found of class #{command_class}")
      end
    end
  end
end
