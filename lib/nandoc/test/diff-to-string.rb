##
# turn the output of Diff::LCS.diff into a string similar
# to what would be retured by `diff`, optionally make it looks
# *sorta* like colorized output from git-diff
#
# @todo move this to minitest branch
# @todo this gives different results than diff for some stuff!!??
#
# poor man's diff:
#   file_a, file_b = ARGV.shift(2)
#   puts DiffToString.files_diff(file_a, file_b)
#
#
class DiffToString
  module Style
    Codes = {:red=>'31', :green=>'32', :bold=>'1', :red_bg=>'41',
      :magenta => '35'
    }
    def stylize str, *codes
      if 1 == codes.size
        if codes.first.nil?
          return str
        elsif codes.first.kind_of?(Array)
          codes = codes.first
        end
      end
      codes = codes.map{|c| Codes[c]}
      "\033[#{codes * ';'}m#{str}\033[0m";
    end
  end
  include Style

  class << self
    # these are just convenience wrappers for instance methods
    %w(diff files_diff strings_diff gitlike!).each do |meth|
      define_method(meth){|*a| new.send(meth,*a) }
    end
  end
  def initialize
    @add_style = nil
    @add_header    = '%sa%s'
    @change_header = '%sc%s'
    @context       = nil
    @del_header    = '%sd%s'
    @del_style = nil
    @last_range = nil
    @left  = '<'
    @line_no_style = nil
    @right = '>'
    @separator_line = '---'
    @trailing_whitespace_style = nil
  end
  attr_accessor :arr1, :arr2 # this is awful bleeding
  def context= mixed
    fail("no #{mixed.inspect}") unless mixed.kind_of?(Fixnum) && mixed >= 0
    @context = mixed == 0 ? nil : mixed
  end
  def gitlike!
    common_header = '@@ -%s, +%s @@'
    @add_header =  common_header
    @add_style = [:bold, :green]
    @change_header = common_header
    @del_style = [:bold, :red]
    @del_header = common_header
    @header_style = [:bold, :magenta]
    @left  = '-'
    @right = '+'
    @separator_line = nil
    @trailing_whitespace_style = [:red_bg]
    self
  end
  def arrays_diff arr1, arr2, opts={}
    diff = Diff::LCS.diff(arr1, arr2)
    @arr1, @arr2 = arr1, arr2
    consume_opts_for_diff(opts)
    diff_to_str diff, opts
  end
  def diff mixed1, mixed2, opts={}
    case (x=[mixed1.class, mixed2.class])
    when [Array,Array];   arrays_diff(mixed1,mixed2,opts)
    when [String,String]; strings_diff(mixed1,mixed2,opts)
    else "no diff strategy for #{x.inspect}"
    end
  end
  def files_diff a, b, opts={:sep=>"\n"}
    str1 = File.read(a)
    str2 = File.read(b)
    strings_diff(str1, str2, opts)
  end
  def strings_diff a, b, opts={}
    opts = opts.merge(:sep=>"\n")
    arr1 = str_to_arr a, opts[:sep]
    arr2 = str_to_arr b, opts[:sep]
    arrays_diff(arr1, arr2, opts)
  end
  def str_to_arr str, sep
    str.split(sep, -1)
  end
  def diff_to_str diff, opts
    consume_opts_for_diff opts
    @out = StringIO.new
    @offset_offset = -1
    diff.each do |chunk|
      context_pre(chunk) if @context
      dels = []
      adds = []
      start_add = last_add = start_del = last_del = nil
      chunk.each do |change|
        case change.action
        when '+'
          start_add ||= change.position + 1
          last_add = change.position + 1
          adds.push change.element
        when '-'
          start_del ||= change.position + 1
          last_del = change.position + 1
          dels.push change.element
        else
          fail("no: #{change.action}")
        end
      end
      if adds.any? && dels.any?
        puts_change_header start_del, last_del, start_add, last_add
      elsif adds.any?
        puts_add_header start_add, last_add
      else
        puts_del_header start_del, last_del
      end
      @offset_offset -= ( dels.size - adds.size )
      dels.each do |del|
        puts_del "#{@left} #{del}"
      end
      if adds.any? && dels.any?
        puts_sep
      end
      adds.each do |add|
        puts_add "#{@right} #{add}"
      end
      context_post(chunk) if @context
    end
    @out.rewind
    @out.read
  end
private
  def consume_opts_for_diff opts
    if opts[:colors]
      opts.delete[:colors]
      gitlike!
    end
    if opts[:context]
      self.context = opts.delete(:context)
    end
  end
  def context_pre chunk
    pos = chunk.first.position - 1
    puts_range_safe pos - @context, pos
  end
  def context_post chunk
    pos = chunk.last.position + 1
    puts_range_safe pos, pos + @context
  end
  def other_offset start
    start + @offset_offset
  end
  def puts_del str
    puts_change str, @del_style
  end
  def puts_add str
    puts_change str, @add_style
  end
  def puts_add_header start_add, last_add
    str = @add_header % [other_offset(start_add), range(start_add,last_add)]
    @out.puts(stylize(str, @header_style))
  end
  def puts_change str, style
    # separate string into three parts! main string,
    # trailing non-newline whitespace, and trailing newlines
    # we want to highlite the trailing whitespace, but if we are
    # colorizing it we need to exclude the final trailing newlines
    # for puts to work correctly
    if /^(.*[^\s]|)([\t ]*)([\n]*)$/ =~ str
      main_str, ws_str, nl_str = $1, $2, $3
      @out.print(stylize(main_str, style))
      @out.print(stylize(ws_str, @trailing_whitespace_style))
      @out.puts(nl_str)
    else
      # hopefully regex never fails but it might
      @out.puts(stylize(str, style))
    end
  end
  def puts_change_header start_del, last_del, start_add, last_add
    str = @change_header %
      [range(start_del,last_del), range(start_add,last_add)]
    @out.puts(stylize(str, @header_style))
  end
  def puts_del_header start_del, last_del
    str =  @del_header % [range(start_del,last_del), other_offset(start_del)]
    @out.puts(stylize(str, @header_style))
  end
  def puts_range_safe start, final
    start = [start, 0].max
    final = [@arr1.size-1, final].min
    if @last_range
      start = [@last_range[1]+1, start].max
      # assume sequential for now! no need to check about previous
      # ones in front of us
    end
    return if start >= final
    @last_range = [start, final]
    @out.puts @arr1[start..final].map{|x| "  #{x}"}
    # @todo i don't know if i'm reading the chunks right
  end
  def puts_sep
    if @separator_line
      @out.puts(@separator_line)
    end
  end
  def range min, max
    if min == max
      min
    else
      "#{min},#{max}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
require 'test/unit'
require 'test/unit/ui/console/testrunner'
class DiffToString::TestCase < Test::Unit::TestCase
  def test_context
    before = <<-B
      alpha
      beta
      gamma
      tau
    B
    after = <<-A
      alpha
      gamma
      zeta
      tau
    A
    puts DiffToString.diff(before.split("\n"), after.split("\n"),
      :colors=>true, :context=>3)
  end
end
Test::Unit::UI::Console::TestRunner.run(DiffToString::TestCase)
end
