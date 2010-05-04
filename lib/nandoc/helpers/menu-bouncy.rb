module NanDoc::Helpers::NanDocHelpers

  #
  # render topnav with one level of menu dropdows
  # with buggy animated opening and closing.
  #
  # usage example:
  #     nandoc_menu_bouncy(binding) do |it|
  #       it.separator = These['❧']
  #       it.tabs = 4
  #     end
  #
  def nandoc_menu_bouncy binding, &block
    MenuBouncy.new(binding, &block).render
  end

  #
  # @api private
  #
  class MenuBouncy
    include NanDoc::StringFormatting
    def initialize(binding, &block)
      @separator_default = '&gt;'
      @tab = '  '
      @tabs = 0
      @item = eval('@item', binding)
      block.call(self)
    end
    attr_accessor :separator_default, :tab, :tabs
    alias_method :separator=, :separator_default=
    alias_method :separator, :separator_default
    alias_method :menu_item_bullet_right, :separator_default
    def render
      item = @item
      chunks = []
      if item.nandoc_sorted_visible_children.any?
        chunks.push render_branch(item)
      else
        chunks.push render_leaf(item)
      end
      while item = item.parent
        chunks.push render_branch(item)
      end
      html = chunks.reverse.join('')
      html2 = reindent html
      html2.strip
    end
  private
    def render_branch item
      [
        render_branch_label(item),
        render_branch_sep_hack(item)
      ].join
    end
    def render_branch_label item
      <<-H
        <div class='nanoc-sidebar-h2  nandoc-menu-lvl-1'>
          #{render_link_or_label(item)}
        </div>
      H
    end
    def render_branch_sep_hack item
      lines = [<<-H
        <div class='bouncy-lvl1-sep'>#{separator}
          <div class='bouncy-lvl2-menu'>
      H
      ]
      cx = item.nandoc_sorted_visible_children
      hh = cx.map{ |x| render_level_2_item(x) }
      lines.concat hh
      lines.push <<-H
          </div>
        </div>
      H
      lines.join
    end
    def render_level_2_item item
      <<-H
            <div class='bouncy-lvl2-item'>
              <span class='bouncy-lvl2-content'>
                #{render_link_or_label(item)}
              </span>
              <span class='bouncy-lvl2-sep'>#{menu_item_bullet_right}</span>
            </div>
      H
    end
    def render_label item
      item.nandoc_title
    end
    def render_leaf item
      <<-H
        <div class='nanoc-sidebar-h2  nandoc-menu-lvl-1'>
          #{render_label(item)}
        </div>
      H
    end
    def render_link_default item
      "<a href='#{item.identifier}'>#{item.nandoc_title}</a>"
    end
    alias_method :render_link, :render_link_default
    def render_link_or_label item
      if item == @item
        render_label item
      else
        render_link item
      end
    end
  end
end
