module NanDoc::Helpers::NanDocHelpers

  include NanDoc::StringFormatting # indent() unindent() no_blank_lines()

  #
  # the recommended way to use this is to copy-paste the contents
  # of {see 'nandoc_sitemap_from_item()'} and tailor it to your whimsy,
  # so that your view code is visible in your templates.
  #
  def nandoc_sitemap mixed, opts={}, &block
    if mixed.kind_of? Array
      sm = NanDocSiteMap.new(mixed, opts, &block)
      sm.is_first = true
      sm.is_last = true
      sm.render_parent
    elsif mixed.kind_of?(Nanoc3::Item)
      nandoc_sitemap_from_item mixed, opts
    else
      fail("fail: #{mixed.inspect}")
    end
  end



  #
  # This is left here as a minimal example but it is recommended that you
  # keep view code in your view templates as opposed to using this function.
  # The point of this whole helper is to expose hooks into typical tree-
  # rendering logic that let you define 1) how to render leaf nodes, 2) how
  # to render branch nodes and 3) and how children of each node are
  # determined.
  #
  # These three components correspond to the three 'setters' used in the
  # below definition block
  #
  # How nodes are rendered for a tree in a given context should not be a
  # concern of this helper, nor should it be concerned with determining
  # which children of each node to render.  (e.g. css classes don't belong
  # here.)  What it *does* do is try to help with indenting logic.
  #
  # see 'nandoc_sitemap()'
  #
  def nandoc_sitemap_from_item home_page, opts={}
    opts = {:tab => '  ', :tabs => 0}.merge(opts)
    nandoc_sitemap([home_page], opts) do |it|
      it.render_parent do |m|
        <<-HTML
        <ul class='nested'>
          #{m.render_children(:tabs=>5, :tab=>'  ')}
        </ul>
        HTML
      end
      it.children_are do |node|
        node.children.select{|c| c.nandoc_visible? }.sort do |a,b|
          a.nandoc_title <=> b.nandoc_title
        end
      end
      it.render_child do |m, node| <<-HTML
        <li class='lvl#{m.level}'>
          #{link_to_unless_current(node.nandoc_title, node.path)}
          #{m.glyphs_right}
          #{m.render_parent}
        </li>
        HTML
      end
    end
  end

  class NanDocSiteMap
    module Glyphs; end # forward declaration
    include Glyphs
    #
    # @api private
    # this used internally to implement the site maps; you shouldn't
    # ever need to instantiate it directly.
    # This is not optimized for speed.  It is optimized for debugging.
    # It is littered with short variable names and narrow, tall chains
    # of statements not because I spent 8 hours debugging this i swear.
    #

    def initialize children, opts, &block
      @children = children
      opts = opts.dup
      @tab = opts.delete(:tab) || '  '
      @tabs = opts.delete(:tabs) || 0
      @level = opts.delete(:level) || 0
      @opts = opts
      @children_are = @render_child = @render_parent = nil
      @block = block
      yield(self) if block_given?
    end
    attr_reader :level, :tabs, :tab
    attr_accessor :is_first, :is_last, :parent, :node

    def children_are &block;
      @children_are = block
    end

    def render_child &block
      raise ArgumentError.new('no') unless block_given?
      @render_child = block
    end

    #
    # unfortunately we keep this one wierd because it makes
    # it a little more clear what's going on from the perspective of the
    # caller (hopefully)
    #
    def render_parent &block
      if block_given?
        @render_parent = block
      else
        do_render_parent
      end
    end

    #
    # reindent a block by striping leading whitespace from lines evenly
    # and then re-indenting each line according to our indent.
    # we could make this more complicated but whatever.
    # it's a goddam static site generator. it could also be simpler!
    #
    def reindent h1, offset=0
      indent_by = @tab * (@tabs+offset)
      unindent_by = (/\A([[:space:]]+)/ =~ h1 && $1) or fail('re fail')
      h2 = no_blank_lines(h1) # careful. will mess up with <pre> etc
      return h2 if unindent_by == indent_by
      h3 = unindent(h2, unindent_by)
      h4 = indent(h3, indent_by)
      h4
    end

    #
    # you need to return a block of <li>'s lined up appropritately
    # Go in two passes (you don't have to), first past set things up
    #
    def render_children child_opts
      cxo = @opts.merge(:level=>@level+1).merge(child_opts)
      fail('no') unless cxo[:tab] && cxo[:tabs]
      last_idx = @children.size - 1
      ch_objs = @children.each.with_index.map do |ch, idx|
        cx = @children_are.call(ch)
        ch_obj = self.class.new(cx, cxo, &@block)
        ch_obj.parent = self
        ch_obj.node = ch
        ch_obj.is_first = idx == 0
        ch_obj.is_last  = idx == last_idx
        ch_obj
      end

      these = ch_objs.map do |ch_obj|
        h1 = @render_child.call(ch_obj, ch_obj.node)
        h2 = ch_obj.reindent(h1)
        h3 = my_strip(h2)
        h3
      end

      hz = these.join("\n" + cxo[:tab] * cxo[:tabs])
      hz
    end

  private

    def do_render_parent
      if @children.empty?
        nil
      else
        h1 = @render_parent.call(self)
        h2 = my_strip(reindent(h1))
        h2
      end
    end

    #
    # wrapped in case we want wierd logic later
    #
    def my_strip str
      str.strip
    end
  end

  module NanDocSiteMap::Glyphs
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
        level == 0 ? [] : begin
          x = [ is_last ? UseThisForBlanks.call(self) : HvVert ]
          x.concat(parent.glyphs_right_for_child) if parent
          x
        end
      end
    end

    def glyphs_right
      these = [ is_last ? ArcUpL : HvVtLf ]
      these.concat( parent.glyphs_right_for_child ) if parent
      # these.concat Array.new([0, level-1].max, DashQV)
      these.join('')
    end
  end
end
