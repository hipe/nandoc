module NanDoc::Helpers::NanDocHelpers

  def nandoc_topnav &block
    TopNav.new(&block).render
  end

  class TopNav
    extend BlockAttrAccessor
    def initialize(&b)
      block_attr_accessor_init
      @current_item = @items = @item = nil
      b.call(self)
    end
    block_attr_accessor :current_item, :item, :separator
    attr_accessor :binding
    def render
      item = eval('@item', @binding)
      temdoz = [@current_item_proc.call(item)]
      while item = item.parent
        temdoz.concat [@separator_proc.call, @item_proc.call(item)]
      end
      temdoz.reverse
    end
    class << self
      def home_page &b
        @home_page ||= b.call
      end
    end
  end
end
