class Nanoc3::Item
  #
  # Little hacks we may or may not use for stuff like sitemap generation.
  #
  class << self
    def sorted_visible_children
      @svc ||= begin
        proc do |node|
          node.children.select{|c| c.nandoc_visible? }.sort_by(&:nandoc_title)
        end
      end
    end
  end


  include NanDoc::StringFormatting # basename_no_extension()

  attr_accessor :identifier # know what you are doing if you set it

  #
  # come up with some title by any means necessary
  #
  def nandoc_title
    if @attributes[:title]
        @attributes[:title]
    elsif ! nandoc_content_node?
      identifier
    elsif no_ext = basename_no_extension(@attributes[:content_filename])
      no_ext.gsub(/[-_]/, ' ') # we could do wiki-name like crap
    elsif ! (foo = File.basename(@attributes[:content_filename])).empty?
      foo
    else
      identifier == '/' ? 'HOME' : identifier.gsub('/',' - ')
    end
  end

  def nandoc_content_node?
    /\A\/css\// !~ identifier # @todo will have to change!
  end

  def nandoc_content_leaf?
    nandoc_content_node? # hm
  end

  def nandoc_content_branch?
    false # hm
  end

  def nandoc_visible?
    !self[:hidden] && path
  end

end
