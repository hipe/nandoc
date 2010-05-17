module NanDoc
  module SharedAttrReader
    #
    # @api private
    # @dependencies none
    #
    # this is a specialized form of delegator pattern: let one object
    # use the responses from another object for a set of accessors
    #
    def shared_attr_reader *list
      fail('no inehiritance yet') if method_defined?(:shared=)
      sm = Module.new
      name = self.to_s+'::SharedAttrReaders'
      sing = class << sm; self end
      sing.send(:define_method, :name){name}
      sing.send(:alias_method, :inspect, :name)
      list.each do |attrib|
        sm.send(:define_method, attrib){ shared.send(attrib) }
      end
      fail('no') if method_defined?(:shared)
      define_method(:shared){ self }
      define_method(:shared=) do |source|
        sing = class << self; self end
        sing.send(:define_method, :shared){ source }
        sing.send(:include, sm) # wow cool that this works w/o having
                                # to Module#undef_method
        source
      end
      nil
    end
  end
end
