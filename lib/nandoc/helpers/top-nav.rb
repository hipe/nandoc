module NanDoc::Helpers::NanDocHelpers

  #
  # nandoc_topnav do |sm|
  #   sm.binding = binding
  #   sm.item { |i| <<-H
  #     <span class='nanoc-sidebar-h2'>#{i.nandoc_title}</span>
  #   H
  #   }
  #   sm.current_item { |i| <<-H
  #     <span class='nanoc-sidebar-h2'>#{i.nandoc_title}</span>
  #   H
  #   }
  #   sm.separator { <<-H
  #     <span class='nanoc-sep'>&#10087;</span>
  #   H
  #   }
  #

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
