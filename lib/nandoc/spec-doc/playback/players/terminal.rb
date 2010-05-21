module NanDoc::SpecDoc::Playback
  class Terminal
    # playback things like as if my name was sega
    #

    include PlaybackMethods
    include Singleton
    include ColorToHtml
    include Nanoc3::Helpers::HTMLEscape

    class << self
      alias_method :get_tag_filter, :instance
    end

    def initialize
      @ellipsis_default = '...'
      @prompt_str_default = '~ > '
      @prompt_str = nil
    end

    def fake_pwd_push new_dir
      /\A(.+) > \Z/ =~ prompt_str or
        fail("can't determine cwd from #{prmpt_str.inspect}")
      new_pwd = "#{$1}/#{new_dir}"
      @old_prompts ||= []
      @old_prompts.push prompt_str
      @prompt_str = "#{new_pwd} > "
      nil
    end

    def fake_pwd_pop
      @prompt_str = @old_prompts.pop
    end

    attr_accessor :ellipsis_default

    attr_accessor :prompt_str_default

    def prompt_str
      @prompt_str ||= @prompt_str_default
    end

    def run_cd out, scn
      node = scn.scan_assert(:cd)
      the_new_directory = node[1]
      html = prompt_highlight2(prompt_str, "cd #{the_new_directory}")
      fake_pwd_push the_new_directory
      out.push_smart 'pre', 'terminal', html
      nil
    end

    def run_cd_end out, scn
      _ = scn.scan_assert(:cd_end)
      fake_pwd_pop
      nil
    end

    def run_command out, scn
      node = scn.scan_assert(:command)
      command_content = node[1]
      html = prompt_highlight2(prompt_str, command_content)
      out.push_smart 'pre', 'terminal', html
      nil
    end

    def run_out out, scn
      node = scn.scan_assert(:out)
      raw = node[1]
      html = terminal_color_to_html(raw) || html_escape(raw)
      out.push_smart 'pre', 'terminal', html
      nil
    end

    def run_out_begin out, scn
      node = scn.scan_assert(:out_begin)
      lines = [node[1].strip]
      if node = scn.scan(:cosmetic_ellipsis)
        lines.push node[1]
      else
        lines.push ellipsis_default
      end
      node = scn.scan_assert(:out_end)
      lines.push node[1]
      raw = lines.join("\n")
      html = terminal_color_to_html(raw) || html_escape(raw)
      out.push_smart 'pre', 'terminal', html
      nil
    end
  end
end
