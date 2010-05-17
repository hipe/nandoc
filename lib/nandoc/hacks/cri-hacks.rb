module Cri
  class Base
    # hack
    include NanDoc::TaskCommon
    def remove_command command_class
      if idx = @commands.index{|x| x.kind_of?(command_class) }
        @commands.delete_at(idx)
      else
        task_abort("command not found of class #{command_class}")
      end
    end
  end
end
