module NanDoc::Helpers::NanDocHelpers

  #
  # @see default.html for example usage.
  #
  def nandoc_sitemap binding, name=nil, &block
    name ||= SiteMap.next_unique_name
    SiteMap.singleton(name, binding, &block).render_parent
  end

  #
  # @api private
  #
  class SiteMap
    extend BlockAttrAccessor, NanDoc::SharedAttrReader
    include NanDoc::SecretParent
    module Glyphs; end # forward declaration
    include Glyphs
    @singletons = {}
    @next_unique_name = -1
    class << self
      def next_unique_name
        @next_unique_name += 1
        @next_unique_name
      end
      def singleton(name, binding, &block)
        @singletons[name] ||= begin
          sing = new
          sing.init_root(binding, &block)
          sing
        end
      end
    end
    def initialize
      @tab = '  '
    end
    attr_accessor :glyphs, :item, :is_first, :is_last,
                  :root_identifier, :tabs, :tab
    attr_reader :level
    block_attr_accessor :children, :render_child # defines *_proc
    shared_attr_reader :children_proc, :glyphs, :tab, :render_child_proc,
      :render_parent_proc # children will access root nodes's attrs for these

    def init_root binding, &block
      block.call(self)
      @is_first = @is_last = true
      @level = 0
      @item = nil
      @tabs ||= 0
      root = eval('@items',binding).find{|x| x.identifier == root_identifier}
      children_populate_recursive [root]
    end
    def init_child parent, item
      self.parent = parent
      @item = item
      self.shared = parent.shared # this does a lot, see SharedAttrReader
      @level = parent.level + 1
      @tabs =  parent.tabs + 1
      cx = children_proc.call(@item)
      children_populate_recursive cx
    end
    def children_populate_recursive cx
      if cx.any? # keep our @children nil unless we have any children
       last_idx = cx.size - 1
        @children = cx.each.with_index.map do |item, idx|
          map = self.class.new
          map.is_first = idx == 0
          map.is_last  = idx == last_idx
          map.init_child self, item
          map
        end
      end
    end

    def merge_opts opts
      fail("just for setting tabs for now") unless opts.keys == [:tabs]
      @tabs = opts[:tabs]
      opts
    end

    # @return [String] <ul> for e.g.  Sets block if given.
    def render_parent &block
      if block_given?
        @render_parent_proc = block
        class << self
          attr_accessor :render_parent_proc
        end
        nil
      elsif @children.nil?
        nil
      else
        h1 = render_parent_proc.call(self)
        h2 = reindent(h1).strip
        h2
      end
    end

    # @return [String] chunk of <li's> for eg.
    def render_children opts={}
      these = @children.map do |map|
        map.merge_opts opts
        h1 = render_child_proc.call(map)
        h2 = map.reindent(h1)
        h3 = h2.strip
        h3
      end
      last = @children.last
      hz = these.join("\n" + last.tab * last.tabs) if last
      hz
    end
  end

  module SiteMap::Glyphs
    # http://www.alanwood.net/unicode/box_drawing.html
    Blank  = '&nbsp;'
    DownLf = '&#9488;' # ┐
    DownRt = '&#9484;' # ┌
    HvVtLf = '&#9515;' # ┫
    HvVert = '&#9475;' # ┃
    UpLeft = '&#9496;' # ┘
    UpRite = '&#9492;' # └
    Vertic = '&#9474;' # │
    VertLf = '&#9508;' # ┤
    VertRt = '&#9500;' # ├
    VtHori = '&#9532;' # ┼
    ArcUpL = '&#9583;' # ╯
    DashQV =' &#9482;' # ┊

    UseThisForBlanks = proc{|node| DashQV }
    # DashQV is nice b/c fixed width

    def glyphs_right_for_child
      @glyphs_right_for_child ||= begin
        case level
        when 0; []     # e.g. the object that is rendering [home]
        when 1; []     # e.g. home, the (lvl2) children have no inheirited
        else
          x = [ is_last ? UseThisForBlanks.call(self) : HvVert ]
          x.concat(parent.glyphs_right_for_child) if parent
          x
        end
      end
    end

    def glyphs_right
      case level
      when 0; fail('never')
      when 1; ''
      else
        these = [ is_last ? ArcUpL : HvVtLf ]
        these.concat( parent.glyphs_right_for_child ) if parent
        # these.concat Array.new([0, level-1].max, DashQV)
        these.join('')
      end
    end
  end
end
