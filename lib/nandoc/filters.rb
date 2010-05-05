require File.dirname(__FILE__)+'/support/regexp-enhance.rb'

module NanDoc::Filters
  class General < ::Nanoc3::Filter
    include Nanoc3::Helpers::HTMLEscape
    alias_method :h, :html_escape

    # Parses document contents for nanDoc enhancements to
    # markdown-like markup.

    # (This is the future home of ridiculous experiments like SpecDoc.)
    # (Plans for nested tags one day maybe.)
    #
    # Currently there is one supported tag, the ruby "code fence"
    #
    # @example the parts in the 'code fence' will be highlighted as ruby:
    #
    #     ## This Is A H2 Header Tag
    #     the following is some ruby.
    #     ruby:
    #     ~~~
    #     foo = Bar.new(:baz => 'biff')
    #     foo.run
    #     ~~~
    #
    # (The line that says "ruby:" should not appear in the output, nor
    # should the triple-tilde "fences" demarcating the code block.)
    #
    # This is designed to degrade gracefully in other contexts, if you're
    # running this only through a kramdown (or other markdown filter)
    # without the nandoc processing.
    #
    # For example if ppl are viewing your README at github, you might
    # want to indent the code inside the fence with 4 spaces so that
    # Github-Flavored Markdown will render it in html <CODE> tags. You
    # won't get the coloring but it will still hopefully look alright.
    #
    # (@todo in the future use 4-space indents instead of code fences?)
    #
    # This is comparable to Nanoc3::Filters::ColorizeSyntax but it works in
    # markdown, not html contexts. (It doesn't really matter what 'type' of
    # file it is in though, if the filter is used sufficiently early and its
    # ouptut doesn't get altered by latter filters.)
    #
    # This has less options than the Nanoc3 ColorizeSyntax filter (zero
    # being less than all positive integers): it uses
    # the ruby gem 'syntax/convertors/html' and outputs html with spans that
    # have different classes for the different types of ruby tokens.
    # (inspired by Trollop documentation.)
    #
    # Create your own stylesheet or use the trollop-like one
    # that is provided by the nanDoc site generator (see the proto/ directory
    # for the actual stylesheet, likely added by default.)
    #
    # There is no magic escaping sequences provided.  You simply cannot have
    # three tildes in your code block, unless you write the html yourself.
    #
    # This was written to be indentation aware, so that your opening fence
    # must have the same amount of indentation as your closing fence.
    #
    # One day maybe, nested blocks will therefor be demarcated by
    # fences with either more *or less* indenation than the demarcating
    # fences in question.
    #
    # Your fences and content can have any leading amount of indent, provided
    # that the opening and closing fence have the same indent.
    # Any leading indent from the fences will be stripped from each line of
    # content provided that each line of content has at least as much indent
    # as the fences.
    #

    include NanDoc::StringFormatting  # oxford_comma


    # @param [String] content The content to filter
    # @param [Hash] params - not used
    # @return [String] The filtered content
    def run content, params={}
      return content unless ReFind =~ content
      require 'syntax/convertors/html'
      @content = content
      @chunks = []
      unparsed_start = 0
      offset = 0
      last = content.length - 1
      while offset <= last && md = ReCapture.match(content[offset..-1])
        unparsed_end = md.offset(0)[0] - 1 + offset
        offset += md.offset(0)[1]+1
        process_unparsed(unparsed_start, unparsed_end)
        unparsed_start = offset # offset is where we start searching next
        process_block(md)
      end
      process_unparsed(unparsed_start, -1)
      @chunks.join('')
    end
    RecognizedTags = ['ruby', 'from the command line']
    ReFind = /^([[:space:]]*)[ a-z]+:[[:space:]]*\n\1~~~[[:space:]]*\n/m
    ReCapture = %r<
      ^((?:[ ]|\t)*)((?:[a-z]|[ ])+):(?:[ ]|\t)*\n
      \1~~~(?:[ ]|\t)*\n
      (.*?)\n
      \1~~~(?:[ ]|\t)*\n
    >mx
    NanDoc::RegexpEnhance.names(ReCapture, :indent, :tag_name, :content)
  private
    def converter_ruby
      @converter_ruby ||= begin
        ::Syntax::Convertors::HTML.for_syntax 'ruby'
      end
    end
    def process_block md
      if ! RecognizedTags.include?(md[:tag_name])
        fail("sorry, there has been a mistake. I shouldn't have parsed it "<<
        "but i went ahead and parsed a #{md[:tag_name].inspect} tag even "<<
        "though i don't know what to do with it.  Known tags are "<<
        oxford_comma(RecognizedTags,&quoted)
        )
      end
      case md[:tag_name]
      when 'ruby'; process_block_ruby md
      when 'from the command line'; process_block_terminal md
      end
    end

    #
    # hackishly use a subset of the ruby styles to hilight parts
    # of otherwise black & white console output.
    # This is not for somehow colorizing colorized output, we will have SpecDoc
    # for that.
    #
    def process_block_terminal md
      content = reindent_content md
      lines = ['<pre class="terminal">'] # hack
      these = content.split("\n").map do |line|
        line.sub( %r!\A(~[^>]*>)?(.*)\Z! ) do |xx|
          tags = [];
          tags.push "<span class='prompt'>#{h($1)}</span>" if $1
          tags.push "<span class='normal'>#{h($2)}</span>" unless $2.empty?
          tags.join('')
        end
      end
      lines.concat these
      lines.push '</pre>'
      html = lines * "\n" + "\n"
      @chunks.push html
    end
    def process_block_ruby md
      content = reindent_content md
      hilited = converter_ruby.convert(content, false)
      pre_block = "\n<pre class='ruby'>\n#{hilited}\n</pre>\n"
      @chunks.push pre_block
    end
    def process_unparsed start, last
      chunk = @content[start..last]
      @chunks.push chunk
    end
    def reindent_content md
      raw_content = md[:content]
      indent = md[:indent]
      return raw_content if indent == ''
      # of all non-blank lines find the minimum indent.
      x = raw_content.scan(/^[[:space:]]+(?=[^[:space:]])/).map(&:length).min
      # if for some reason the content has less indent than the fences,
      # don't alter any of it.
      return raw_content if x < indent.length
      re = /^#{Regexp.new(indent)}/
      unindented_content = raw_content.gsub(re, '')
      unindented_content
    end
  end
end
