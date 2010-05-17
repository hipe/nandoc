module NanDoc
  module SecretParent
    #
    # @dependencies: none
    # @api private
    # set parent attribute without it showing up in inspect() dumps
    #
    def parent= mixed
      fail("no clear_parent() available yet.") unless mixed
      @has_parent = !! mixed
      class << self; self end.send(:define_method, :parent){mixed}
      mixed # maybe chain assignmnet of 1 parent to several cx at once
    end
    def parent?
      instance_variable_defined?('@has_parent') && @has_parent # no warnings
    end
    def parent
      nil
    end
  end
end
