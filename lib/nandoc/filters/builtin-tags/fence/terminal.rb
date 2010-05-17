require 'nandoc/spec-doc/playback'
require 'nandoc/spec-doc/ruby2ruby-standin'

module NanDoc::Filters::Fence
  class Terminal
    include NanDoc::SpecDoc::Ruby2RubyStandin
    include NanDoc::SpecDoc::Playback::Terminal::ColorToHtml

    class << self
      def =~ str
        str =~ /\Afrom the command line\Z/
      end
    end

    def run out, indent, label, content
      content_ind = reindent_content content, indent
      # if color codes colorize color codes, else prompts
      html = terminal_color_to_html(content_ind)
      html ||= prompt_highlight(content_ind)
      out.push_tag_now 'pre', 'terminal', html
      nil
    end
  end
end
