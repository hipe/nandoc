require 'ruby-debug'
require 'syntax/convertors/html'
require 'nandoc/spec-doc/ruby2ruby-standin'

# require 'nandoc/spec-doc/playback'


module NanDoc::SpecDoc::Playback
  class Ruby
    # playback things like as if my name was sega
    #

    include NanDoc::SpecDoc::Ruby2RubyStandin # re_for_*
    include PlaybackMethods
    include Singleton

    class << self
      alias_method :get_tag_filter, :instance
    end

    def initialize
      @here = NanDoc::Regexp.new( /\A(.*)(?:, ?<<-'?([A-Z]+))/,
                                     :keep,          :here)

      @inspect = NanDoc::Regexp.new(
        /\A([ \t]*)(?:nandoc\.inspect[ \t]*)(.+)\Z/,
        :indent,   :tail)

      @prefix = '# '

      @re_out = NanDoc::Regexp.new(/\A[ \t]*nandoc\.out\([ \t]*<<-'?([A-Z]+)/)

      @re_until_do = /\A[ \t]*\)[ \t]*do[ \t]*\Z/
    end

    def run_record_ruby out, scn
      node = scn.scan_assert(:record_ruby)
      code = node[1]
      @file_lines = code.file_lines.dup # we change the originals
      while ! scn.eos? && [:inspect, :out].include?(curr = scn.current.first)
        case curr
        when :inspect; process_inspect(scn)
        when :out;     process_out(scn)
        else fail("do me: #{curr.inspect}")
        end
      end
      these = @file_lines[code.start_at[:line]..code.stop_at[:line]-2]
      block = these.join('')
      unind = unindent(block)
      unind.chomp! # sure why not
      conv = ::Syntax::Convertors::HTML.for_syntax('ruby')
      html = conv.convert(unind, false)
      out.push_smart 'pre', 'ruby', html
      nil
    end

  private

    # @todo stuff could be cleaned up to use StringScanner but why?

    # @return void. change @file_lines
    def inspect_oneline node
      offset = node[2][:line] - 1
      line = @file_lines[offset]
      /\A([ \t]*)nandoc.inspect *([^,]+), *([^,]+)\n\Z/ =~ line or fail(
        "DocSpec hack fail: Why can't we parse this inspect "<<
        " line?\n#{line.inspect}")
      ind, keep, val = $1, $2, $3 # actually we don't want $3
      replace_with = "#{ind}#{keep}\n#{ind}#{@prefix}#{node[1]}\n"
      # assume no newlines in value when the whole thing was oneline
      @file_lines[offset] = replace_with
      nil
    end

    # @return void. change @file_lines
    def process_inspect scn
      node = scn.scan_assert(:inspect)
      offset = node[2][:line] - 1
      act = @file_lines[offset]
      md = @inspect.match_assert(act)
      md = md.to_hash
      tail = md[:tail]
      my_lines = []
      md2 = @here.match(tail) or return inspect_oneline(node)
      md2 = md2.to_hash
      ind = leading_indent(@file_lines[offset])
      my_lines.push "#{ind}#{md2[:keep]}\n"
      re = re_for_here(md2[:here])
      j = offset + 1
      last = @file_lines.length - 1
      until re =~ @file_lines[j] || j > last
        back_one = @file_lines[j].sub(/\A(?:  |\t)/,'')
        my_lines.push back_one.sub(/\A([\t ]*)/){ "#{$1}#{@prefix}" }
        j += 1
      end
      j > last && fail("DocSpec hack fail: #{md2[:here]} not found "<<
        "anywhere before EOF")
      (offset..j).each do |k|
        @file_lines[k] = nil
      end
      (0..my_lines.length-1).each do |k|
        l = offset+k
        @file_lines[l] = my_lines[k]
      end
      nil
    end


    # the block content gets output as if it's bare ruby,
    # the output (whether it was expected or actual we don't care)
    # gets output with leading comment markers.  All of this nonsense is
    # bs proof of concept that needs to get blown away by ruby2ruby or
    # something
    #
    def process_out scn
      node = scn.scan_assert(:out)
      call_offset = node[2][:line] - 1
      first = @file_lines[call_offset]
      @re_out.match_assert(first, 'nandoc.out line')
      j = call_offset + 1
      last = @file_lines.length - 1
      j += 1 until j > last || @re_until_do =~ @file_lines[j]
      j <= last or fail("DocSpec hack fail: Couldn't find do block "<<
        "anywhere before EOF with #{ReUntilDo}")
      do_line = @file_lines[j]
      re = re_for_line_with_same_indent_as(do_line)
      repl_lines = []
      j += 1
      repl_from_here = j
      j += 1 until j > last || re =~ @file_lines[j]
      j <= last or fail("DocSpec hack fail: Couldn't find end of do "<<
        "block anywhere before EOF with #{re}")
      offset_of_line_with_end = j
      repl_lines = @file_lines[repl_from_here..offset_of_line_with_end-1]
      repl_lines.any? or fail("DocSpec hack fail -- no lines")
      ind_short = leading_indent(do_line)
      ind_long  = leading_indent(repl_lines.first)
      ind_diff = string_diff_assert(ind_long, ind_short)
      unindent = re_for_unindent_gsub(ind_diff)
      repl_lines.map{ |x| x.sub!(unindent, '') }
        # this changes @file_lines val
      (0..repl_lines.length-1).each do |l|
        actual_offset = call_offset + l
        @file_lines[actual_offset] = repl_lines[l]
      end
      erase_from_here = call_offset + repl_lines.length
      (erase_from_here..offset_of_line_with_end).each do |l|
        @file_lines[l] = nil
      end
      # this is so fragile, it requires multiline blah blah
      commented_content = node[1].gsub(/^/m, "#{ind_short}#{@prefix}")
      @file_lines[erase_from_here] = commented_content
      nil
    end
    def re_for_here here
      /\A[ \t]*#{Regexp.escape(here)}[ \t]*\n?\Z/
    end
  end
end
