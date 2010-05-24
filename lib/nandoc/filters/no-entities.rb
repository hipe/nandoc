module NanDoc::Filters
  class NoEntities < ::Nanoc3::Filter
    # change some named character entity references to their numerical
    # equivalent for use in xhtml documents (is this necessary?)
    # selected subset from:
    # http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
    Map = {
      'gt'    => 62,
      'ldquo' => 8220,
      'lt'    => 60,
      'rdquo' => 8221,
      'rsquo' => 8217
    }
  public
    def run content, params={}
      new_content = content.gsub(/&([a-z]+);/) do
        if use_this = Map[$1]
          "&##{use_this};"
        else
          fail("sorry i'm being lame about this. get thing for &#{$1};")
        end
      end
      new_content
    end
  end
end
