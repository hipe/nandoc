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

    def unindent_generic str
      md = ReUnindent.match(str) or fail("no")
      reindent_content(md)
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

    ReSeeTestParse =
      /\A((?:spec|test).*\.rb) ?(?:--?|\/) ?['"]([^'"]+)['"](.+)?\Z/
    NanDoc::RegexpEnhance.names(ReSeeTestParse, :testfile, :testname, :xtra)

    ReUnindent = /\A([ \t]*)(.*)\Z/m
    NanDoc::RegexpEnhance.names(ReUnindent, :indent, :content)

    def initialize(*a)
      super(*a)
      @prompt_str = prompt_str_default
    end

    def advance_to_story sexp, md, idx
      story = md[:xtra] =~ /\A *(?:--?|\/) *['"](.+)['"]\Z/ && $1 or
        fail("couldn't parse out story name from #{md[:xtra].inspect}"<<
        "expecting for e.g  \" - 'blah blah'\"")
      idx = sexp.index{|x| x.first == :story && x[1] == story } or
        fail("couldn't find story #{story.inspect}.  Known stories are: ("<<
        sexp.select{|x| x.first == :story }.map{|x| "'#{x[1]}'"}.join(', ')<<
        ")")
      idx + 1
    end

    def converter_ruby
      @converter_ruby ||= begin
        require 'syntax/convertors/html'
        ::Syntax::Convertors::HTML.for_syntax 'ruby'
      end
    end

    def sexp_getter
      @sexp_getter ||= begin
        require File.dirname(__FILE__)+'/spec-doc.rb'
        NanDoc::SpecDoc::
          TestFrameworkDispatcher.new(current_project_root_hack)
      end
    end

    #
    # @todo this sucks.  i didn't have time to think about how this should
    # work when i wrote it.  The problem is, given that we are a nanoc
    # project, how do we know where live the tests we are spec-docing?
    #
    # For now we assume that the mysite folder is one level inside the root
    # of the (gem-like) project folder and we assert that the assumed root
    # looks right but this will be broken in the likely event that the nanoc
    # project will live elsewhere relative to the gem-like root.
    #
    def current_project_root_hack
      presumed_root = File.dirname(FileUtils.pwd)
      thems = %w(spec test)
      found = thems.detect{ |dir| File.directory?(presumed_root+'/'+dir) }
      fail("couldn't find " << oxford_comma(thems,' or ', &quoted) <<
        "in #{presumed_root}") unless found
      presumed_root
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

    def prompt_str_cd new_dir
      /\A(.+) > \Z/ =~ prompt_str or
        fail("can't determine cwd from #{prmpt_str.inspect}")
      new_pwd = "#{$1}/#{new_dir}"
      @old_prompts ||= []
      @old_prompts.push prompt_str
      @prompt_str = "#{new_pwd} > "
      nil
    end

    def prompt_str_cd_pop
      @prompt_str = @old_prompts.pop
    end

    def prompt_str_default
      '~ > '
    end

    public # avoid warnings
    attr_reader :prompt_str
    private :prompt_str
    private

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
      md2 = ReSeeTestParse.match(md[:content]) or
        fail("couldn't parse see_test string: #{md[:content].inspect} -- "<<
         'string must look like: \'(see: test_file.rb/"some test name")\''
        )
      getter = sexp_getter
      sexp = getter.get_sexp md2[:testfile], md2[:testname]
      sexp.first.first == :method or fail("i'm done with this kind of sexp")
      methname = sexp.first[1]
      idx = 0
      last = sexp.length - 1
      if md2[:xtra]
        idx = advance_to_story(sexp, md2, idx)
      end
      idx += 1 if sexp[0] && sexp[0].first == :method && idx == 0
      catch(:done) do
        while idx <= last
          node = sexp[idx]
          type = node.first
          case type
          when :cd, :command
            idx += process_sexp_command sexp, idx
          when :method
            if node[1] != methname
              fail("i don't like this kind of sexp anymore -- "<<
                "#{methname.inspect} != #{node[1].inspect}"
              )
            end
          when :note
            process_sexp_note sexp, idx
          when :record_ruby
            idx += ProcessSnippet.new(self, sexp, idx).process
          when :story
            # always stop at next story?
            throw :done
          else
            fail("unexpected sexp node here: #{type.inspect} idx: #{idx}")
          end
          idx += 1
        end
      end
    end

    def render_block_fence_terminal md
      content = reindent_content md
      render_terminal_div_highlighted content
    end

    def render_block_fence_ruby md
      content = reindent_content md
      content2 = content.strip # i think
      hilited = converter_ruby.convert(content2, false)
      pre_block = "\n<pre class='ruby'>\n#{hilited}\n</pre>\n"
      @chunks.push pre_block
    end
    public :render_block_fence_ruby # visitors

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
          when :cd;       lines.push "#{prompt_str}cd #{sexp[j][1]}"
                          prompt_str_cd sexp[j][1]
          when :cd_end;   prompt_str_cd_pop
          when :command;  lines.push "#{prompt_str}#{sexp[j][1]}"
          when :out;      lines.push sexp[j][1].strip
          when :out_begin
            j += process_sexp_ellipsis lines, sexp, j
          else;
            j -= 1 unless j == i
            throw :done
          end
          j += 1
        end
      end
      raw_content = lines.join("\n")
      render_terminal_div_highlighted raw_content
      ret = j-i
      ret
    end

    # @return [nil] adds the output raw to the blickle blackle
    def process_sexp_note sexp, idx
      chunk = sexp[idx][1].call
      @chunks.push chunk
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

    # ignoring multiline crap for now
    def ruby_snippet_inspect inspect
      "\n#=> #{inspect}"
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

    module HackHelpers
      # stand-in for ruby-2-ruby
      #

      def leading_indent str
        /\A([ \t]*)/ =~ str && $1
      end
      def re_for_line_with_same_indent_as str
        ind = leading_indent(str)
        re = /\A#{Regexp.escape(ind)}(?=[^ \t])/
        re
      end
      def re_for_here here
        /\A[ \t]*#{Regexp.escape(here)}[ \t]*\n?\Z/
      end
      def re_for_unindent_gsub indent
        re = /\A#{Regexp.escape(indent)}/
        re
      end
      def string_diff_assert long, short
        idx = long.index(short) or fail("short not found in long -- "<<
        "#{short.inspect} in #{long.inspect}")
        head = long[0,idx] # usu. ''
        tail = long[idx + short.length..-1]
        head + tail
      end
    end

    class ProcessSnippet
      include HackHelpers

      def initialize filter, sexp, idx
        @prefix = '# => '
        sexp[idx].first == :record_ruby or fail("must be record_ruby")
        @filter, @sexp, @idx = filter, sexp, idx
      end
      ReInspect =  /\A([ \t]*)(?:nandoc\.inspect[ \t]*)(.+)\Z/
      NanDoc::RegexpEnhance.names(ReInspect, :indent, :tail)
      ReOut     = /\A[ \t]*nandoc\.out\([ \t]*<<-'?([A-Z]+)/
      ReUntilDo = /\A[ \t]*\)[ \t]*do[ \t]*\Z/

      ReHere = /\A(.*)(?:, ?<<-'?([A-Z]+))/
      NanDoc::RegexpEnhance.names(ReHere, :keep, :here)

      ConsumeThese = [:inspect, :out]

      def process
        j = @idx
        snip = @sexp[j][1]
        @lines = snip.file_lines.dup # we will be changing values
        @inspects = []
        while @sexp[j+1] && ConsumeThese.include?(@sexp[j+1].first)
          j += 1
          @inspects.push @sexp[j]
        end
        inspects_interpolate if @inspects.any?
        unindented_lines = @lines[snip.line_start..snip.line_stop-2]
        fake_unindented_ruby = unindented_lines.compact.join('')
        indent = /\A([ \t]*)/ =~ fake_unindented_ruby && $1
        fake_md = {:indent => indent, :content => fake_unindented_ruby}
        @filter.render_block_fence_ruby(fake_md)
        advance_by = j - @idx
        advance_by
      end
    private
      def erase_to_here offset, here
        re = /\A[ \t]*#{Regexp.escape(here)}\Z/
        found = (offset+1..@lines.length-1).detect{|idx| @lines[idx] =~ re }
        found or fail("heredoc hack failed. no #{re} found.")
        (offset+1..found).each{ |idx| @lines[idx] = nil }
        nil
      end

      # whether with a nandoc.out or nandoc.inspect, keeping the indentation
      # that's in the sourcefile, substitute real code for pretty code,
      # without changing the offsets of the lines.  fragile hack.
      # @todo ruby2ruby?
      #
      def inspects_interpolate
        @inspects.each do |ins|
          # each call below will alter @lines (without shifting them)
          # accordingly, replacing actual code with pretty code (and comments)
          case ins[0]
          when :inspect; process_inspect(ins)
          when :out;     process_out(ins)
          else fail("no: #{ins[0].inspect}")
          end
        end
      end

      # the block content gets output as if it's bare ruby,
      # the output (whether it was expected or actual we don't care)
      # gets output with leading comment markers.  All of this nonsense is
      # bs proof of concept that needs to get blown away by ruby2ruby or
      # something
      #
      def process_out sexp
        call_offset = sexp[2][:line] - 1
        first = @lines[call_offset]
        ReOut =~ first or fail("DocSpec hack fail: Didn't look like "<<
          "nandoc.out line: #{first.inspect}\nExpecting line to match "<<
          " #{reOut}")
        j = call_offset + 1
        last = @lines.length - 1
        j += 1 until j > last || ReUntilDo =~ @lines[j]
        j <= last or fail("DocSpec hack fail: Couldn't find do block "<<
          "anywhere before EOF with #{ReUntilDo}")
        do_line = @lines[j]
        re = re_for_line_with_same_indent_as(do_line)
        repl_lines = []
        j += 1
        repl_from_here = j
        j += 1 until j > last || re =~ @lines[j]
        j <= last or fail("DocSpec hack fail: Couldn't find end of do "<<
          "block anywhere before EOF with #{re}")
        offset_of_line_with_end = j
        repl_lines = @lines[repl_from_here..offset_of_line_with_end-1]
        repl_lines.any? or fail("DocSpec hack fail -- no lines")
        ind_short = leading_indent(do_line)
        ind_long  = leading_indent(repl_lines.first)
        ind_diff = string_diff_assert(ind_long, ind_short)
        unindent = re_for_unindent_gsub(ind_diff)
        repl_lines.map{ |x| x.sub!(unindent, '') } # this changes @lines val
        (0..repl_lines.length-1).each do |l|
          actual_offset = call_offset + l
          @lines[actual_offset] = repl_lines[l]
        end
        erase_from_here = call_offset + repl_lines.length
        (erase_from_here..offset_of_line_with_end).each do |l|
          @lines[l] = nil
        end
        # this is so fragile, it requires multiline blah blah
        commented_content = sexp[1].gsub(/^/m, "#{ind_short}# ")
        @lines[erase_from_here] = commented_content
        nil
      end

      #
      # comments at process_out apply to this too
      #
      def process_inspect sexp
        offset = sexp[2][:line] - 1
        act = @lines[offset]
        md = ReInspect.match(act) or
          fail("hack fail of nandoc.inspect near #{act.inspect}")
        md = md.to_hash
        tail = md[:tail]
        my_lines = []
        md2 = ReHere.match(tail)
        return process_inspect_oneline(sexp) unless md2
        md2 = md2.to_hash
        ind = leading_indent(@lines[offset])
        my_lines.push "#{ind}#{md2[:keep]}\n"
        re = re_for_here(md2[:here])
        j = offset + 1
        last = @lines.length - 1
        until re =~ @lines[j] || j > last
          back_one = @lines[j].sub(/\A(?:  |\t)/,'')
          my_lines.push back_one.sub(/\A([\t ]*)/){ "#{$1}#{@prefix}" }
          j += 1
        end
        j > last && fail("DocSpec hack fail: #{md2[:here]} not found "<<
          "anywhere before EOF")
        (offset..j).each do |k|
          @lines[k] = nil
        end
        (0..my_lines.length-1).each do |k|
          l = offset+k
          @lines[l] = my_lines[k]
        end
      end

      def process_inspect_oneline sexp
        offset = sexp[2][:line] - 1
        line = @lines[offset]
        /\A([ \t]*)nandoc.inspect *([^,]+), *([^,]+)\n\Z/ =~ line or fail(
          "DocSpec hack fail: Why can't we parse this inspect "<<
          " line?\n#{line.inspect}")
        ind, keep, val = $1, $2, $3 # actually we don't want $3
        replace_with = "#{ind}#{keep}\n#{ind}#{@prefix}#{sexp[1]}\n"
        # assume no newlines in value when the whole thing was oneline
        @lines[offset] = replace_with
        nil
      end
    end
  end
end
