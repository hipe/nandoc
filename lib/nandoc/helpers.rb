module NanDoc::Helpers
  module NanDocHelpers
    # @todo-now test this
    include NanDoc::StringFormatting # indent() unindent() no_blank_lines()
    module BlockAttrAccessor
      attr_accessor :block_attr_accessors
      class << self
        def extended mod
          mod.instance_variable_set('@block_attr_accessors', []) unless
            mod.instance_variable_defined?('@block_attr_accessors')
          mod.send(:define_method, :block_attr_accessor_init) do
            self.class.block_attr_accessors.each do |name|
              instance_variable_set("@#{name}_proc",nil) unless
                instance_variable_defined?("@#{name}_proc")
            end
          end
        end
      end
      def block_attr_accessor *names
        names.each do |setter_name|
          @block_attr_accessors.push(setter_name) # etc
          attr_name = "@#{setter_name}_proc"
          getter_name = "#{setter_name}_proc"
          define_method(setter_name) do |&block|
            raise ArgumentError.new(
              "no block given for #{self.class}##{setter_name}"
            ) unless block
            instance_variable_set attr_name, block
          end
          define_method(getter_name) do
            instance_variable_get attr_name
          end
        end
      end
    end
  end
end

here = File.dirname(__FILE__)+'/helpers'
require here + '/menu-bouncy.rb'
require here + '/site-map.rb'
require here + '/top-nav.rb'
