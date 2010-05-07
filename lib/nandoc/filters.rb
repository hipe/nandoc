require File.dirname(__FILE__)+'/support/regexp-enhance.rb'

module NanDoc::Filters
  class General < ::Nanoc3::Filter
    include Nanoc3::Helpers::HTMLEscape
    alias_method :h, :html_escape

    module TerminalColorToHtml; end
    include TerminalColorToHtml

    # Parses document contents for nanDoc enhancements to
    # markdown-like markup.

    # These are the supported tags:
    #   * a ruby "code fence"  (indicated with 'ruby:')
    #   * a terminal "code fence" (indicated with 'from the command line:')
    #   * example injection from unit tests
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
    # (Plans for nested tags one day maybe.
    # One day maybe, nested blocks will therefor be demarcated by
    # fences with either more *or less* indenation than the demarcating
    # fences in question.(?))
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
      content = filter_fence(content) if ReFenceFind =~ content
      content = filter_see_test(content) if ReSeeTest =~ content
      content
    end

  private

    RecognizedTags = ['ruby', 'from the command line']
    ReFenceFind = /^([[:space:]]*)[ a-z]+:[[:space:]]*\n\1~~~[[:space:]]*\n/m
    ReFenceCap = %r<
      ^((?:[ ]|\t)*)((?:[a-z]|[ ])+):(?:[ ]|\t)*\n
      \1~~~(?:[ ]|\t)*\n
      (.*?)\n
      \1~~~(?:[ ]|\t)*\n
    >mx
    NanDoc::RegexpEnhance.names(ReFenceCap, :indent, :tag_name, :content)

    ReSeeTest = /\(see: ((?:spec|test)[^\)]+)\)/
    NanDoc::RegexpEnhance.names(ReSeeTest, :content)

    ReSeeTestParse = /\A((?:spec|test).*\.rb) ?(?:--?|\/) ?['"](.+)['"]\Z/
    NanDoc::RegexpEnhance.names(ReSeeTestParse, :testfile, :testname)

    def converter_ruby
      @converter_ruby ||= begin
        require 'syntax/convertors/html'
        ::Syntax::Convertors::HTML.for_syntax 'ruby'
      end
    end

    def converter_specdoc
      @converter_specdoc ||= begin
        require File.dirname(__FILE__)+'/spec-doc.rb'
        NanDoc::SpecDoc.new(NanDoc::Root)
      end
    end

    def ellipsis_default
      "..."
    end

    def filter_fence content
      with_each_tag_in(content, ReFenceCap) do |md|
        render_block_fence md
      end
    end

    def filter_see_test content
      # require File.dirname(__FILE__)+'/spec-doc.rb'
      with_each_tag_in(content, ReSeeTest) do |md|
        render_block_see_test md
      end
    end

    #
    # if the string has anything that looks like colors in it,
    # then just highlite the colors (as html), else
    # highlight things that look like prompts (as html)
    #
    def lines_highlighted content
      if colored_content = terminal_color_to_html(content)
        [colored_content]
      else
        these = content.split("\n").map do |line|
          line.sub( %r!\A(~[^>]*>)?(.*)\Z! ) do
            tags = [];
            tags.push "<span class='prompt'>#{h($1)}</span>" if $1
            tags.push "<span class='normal'>#{h($2)}</span>" unless $2.empty?
            tags.join('')
          end
        end
        these
      end
    end

    # @return the amount to advance the cursor by
    def process_sexp_ellipsis lines, sexp, i
      j = i
      fail("need :out_begin") unless sexp[j].first == :out_begin
      lines.push sexp[j][1].strip
      j += 1
      if sexp[j] && sexp[j].first == :cosmetic_ellipsis
        lines.push sexp[j][1]
        j += 1
      else
        lines.push ellipsis_default
      end
      fail("need :out_end") unless sexp[j] && sexp[j].first == :out_end
      lines.push sexp[j][1]
      ret = j - i
      ret
    end

    def prompt_str
      '~ > '
    end

    def render_block_fence md
      if ! RecognizedTags.include?(md[:tag_name])
        fail("sorry, there has been a mistake. I shouldn't have parsed it "<<
        "but i went ahead and parsed a #{md[:tag_name].inspect} tag even "<<
        "though i don't know what to do with it.  Known tags are "<<
        oxford_comma(RecognizedTags,&quoted)
        )
      end
      case md[:tag_name]
      when 'ruby'; render_block_fence_ruby md
      when 'from the command line'; render_block_fence_terminal md
      end
    end

    def render_block_see_test md
      md = ReSeeTestParse.match(md[:content]) or
        fail("couldn't parse see_test string: #{md[:content].inspect} -- "<<
         'string must look like: \'(see: test_file.rb/"some test name")\''
        )
      specdoc = converter_specdoc
      sexp = specdoc.get_sexp md[:testfile], md[:testname]
      i = -1
      last = sexp.length - 1
      while( (i+=1) <= last )
        node = sexp[i]
        type = node.first
        case type
        when :method; # skip
        when :command
          i += process_sexp_command sexp, i
        else fail("unexpected sexp node here: #{type.inspect}")
        end
      end
    end

    def render_block_fence_terminal md
      content = reindent_content md
      render_terminal_div_highlighted content
    end

    def render_block_fence_ruby md
      content = reindent_content md
      hilited = converter_ruby.convert(content, false)
      pre_block = "\n<pre class='ruby'>\n#{hilited}\n</pre>\n"
      @chunks.push pre_block
    end

    def render_command_div content
      fake_command = "#{prompt_str}#{content}"
      render_terminal_div_highlighted fake_command
    end

    # @return [integer] how much to advance the cursor by
    # when you either hit the end or hit an unrecognized node
    # adds to rendered output a div with the command and output
    def process_sexp_command sexp, i
      lines = []
      j = i
      last = sexp.length - 1
      catch(:done) do
        while j <= last
          type = sexp[j].first
          case type
          when :command;  lines.push "#{prompt_str}#{sexp[j][1]}"
          when :out;      lines.push sexp[j][1].strip
          when :out_begin;
            j += process_sexp_ellipsis lines, sexp, j
          else; throw :done
          end
          j += 1
        end
      end
      raw_content = lines.join("\n")
      render_terminal_div_highlighted raw_content
      ret = j-i
      ret
    end

    def render_terminal_div_highlighted content
      lines = ['<pre class="terminal">']
      lines.concat lines_highlighted(content)
      lines.push '</pre>'
      html = lines * "\n" + "\n"
      @chunks.push html
    end

    def render_unparsed start, last
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

    def with_each_tag_in content, regexp, &block
      @content = content
      @chunks = []
      unparsed_start = 0
      offset = 0
      last = content.length - 1
      while offset <= last && md = regexp.match(content[offset..-1])
        unparsed_end = md.offset(0)[0] - 1 + offset
        offset += md.offset(0)[1]+1
        render_unparsed(unparsed_start, unparsed_end)
        unparsed_start = offset # offset is where we start searching next
        block.call(md)
      end
      render_unparsed(unparsed_start, -1)
      @chunks.join('')
    end

    require 'strscan'
    module TerminalColorToHtml
      # this sucks.
      #
      def terminal_color_to_html str
        return nil unless str.index("\e[") # save a whale
        scn = StringScanner.new(str)
        sexp = []
        while true
          foo = scn.scan(/(.*?)(?=\e\[)/m)
          if ! foo
            blork = scn.scan_until(/\Z/m) or fail("worglebezoik")
            sexp.push([:content, blork]) unless blork.empty?
            break;
          end
          foo or fail("oopfsh")
          sexp.push([:content, foo]) unless foo.empty?
          bar = scn.scan(/\e\[/) or fail("goff")
          baz = scn.scan(/\d+(?:;\d+)*/)
          baz or fail("narghh")
          if '0'==baz
            sexp.push([:pop])
          else
            sexp.push([:push, *baz.split(';')])
          end
          biff = scn.scan(/m/) or fail("noiflphh")
        end
        html = terminal_colorized_sexp_to_html sexp
        html
      end
    private
      # the other side of these associations lives in trollop-subset.css
      Code2CssClass = {
        '1' => 'bright',  '30' => 'black', '31' => 'red', '32' => 'green',
        '33' => 'yellow', '34' => 'blue', '35' => 'magenta', '36' => 'cyan',
        '37' => 'white'
      }
      def terminal_code_to_css_class code
        Code2CssClass[code] or
          fail("sorry, no known code for #{code.inspect}. "<<
          "(maybe you should make one?)")
      end
      def terminal_colorized_sexp_to_html sexp
        i = -1;
        last = sexp.length - 1;
        parts = []
        catch(:done) do
          while (i+=1) <= last
            codes = nil
            while i <= last && sexp[i].first == :push
              codes ||= []
              codes.concat sexp[i][1..-1]
              i += 1
            end
            if codes
              classes = codes.map{|c| terminal_code_to_css_class(c) }*' '
              parts.push "<span class='#{classes}'>"
            end
            throw :done if i > last
            case sexp[i].first
              when :content; parts.push(sexp[i][1])
              when :pop; parts.push('</span>')
              else; fail('fook');
            end
          end
        end
        html = parts*''
        html
      end
    end
  end
end
