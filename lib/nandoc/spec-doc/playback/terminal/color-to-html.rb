module NanDoc; end
module NanDoc::SpecDoc; end
module NanDoc::SpecDoc::Playback; end
class NanDoc::SpecDoc::Playback::Terminal; end
module NanDoc::SpecDoc::Playback::Terminal::ColorToHtml


  include Nanoc3::Helpers::HTMLEscape
  alias_method :h, :html_escape


  # look for things that look like prompts and make them brighter
  # @todo html escape vis-a-vis blah
  def prompt_highlight str
    lines = str.split("\n")
    linez = lines.map do |line|
      line.sub( %r!\A(~[^>]*>)?(.*)\Z! ) do
        tags = [];
        tags.push "<span class='prompt'>#{h($1)}</span>" if $1
        tags.push "<span class='normal'>#{h($2)}</span>" unless $2.empty?
        tags.join('')
      end
    end
    html = linez.join("\n")
    html
  end
  
  def prompt_highlight2 prompt, cmd
    "<span class='prompt'>#{h(prompt)}</span>"<<
    "<span class='normal'>#{h(cmd)}</span>\n"
  end
  
  # this sucks.
  #
  # the other side of these associations lives in trollop-subset.css
  Code2CssClass = {
    '1' => 'bright',  '30' => 'black', '31' => 'red', '32' => 'green',
    '33' => 'yellow', '34' => 'blue', '35' => 'magenta', '36' => 'cyan',
    '37' => 'white'
  }      
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
