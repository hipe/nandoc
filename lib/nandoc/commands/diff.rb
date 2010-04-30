support =  File.expand_path('../../support', __FILE__)
require support + '/diff-proxy.rb'
require support + '/path-tardo.rb'
require support + '/site-methods.rb'

module NanDoc::Commands
  class Diff < ::Cri::Command
    NanDoc.persistent_delegate_to(self) # persistent_set(), persistent_get()
    include NanDoc::CliCommandHelpers, NanDoc::PathTardo, NanDoc::SiteMethods

    def name; 'diff' end

    def aliases; [ 'd' ] end

    def short_desc; 'maybe push and pull some stuff (nanDoc hack)' end

    def long_desc
      <<-LONG_DESC.gsub(/\n +/,' ')
      This eases the ridiculous pain of tweaking your generated css
      and wanting to push it back to your <my-site> folder, and maybe
      other things like that.
      \n
      Patch <my-site>/content with what's in <my-site>/output with
      (--content-to-output|-c).  This is the default.
      \n
      Patch <prototypes>/<the-prototype> with what's in <my-site>/content
      with (--content-to-prototype|-p).  This would be for altering the
      nanDoc prototypes with what you have in your <my-site> folder.  This
      would be for hacking nanDoc.
      \n
      Wierd bonus feature: Do the reverse of the above with -P or -C.
      \n
      This operates on a subset of the trees, for now only the files in the
      'css/' folder. (you can use the --css option for this but there is no
      reason to at the time of this writing.)
      \n
      (In the future it might support more options for patching
      prototypes with entire <my-sites>)
      \n
      So, with this wierd chain, you can tweak your CSS, for example,
      in the generated output and then push these changes all the way back to
      the prototype with -cY and then -pY

      Or you can undo your changes pulling all the way back from the prototype
      with -PY and then -CY
      LONG_DESC
    end

    def usage; "nandoc diff [-c|-C|-p|-P] [--css|] [-Y] [<path>]" end

    def option_definitions
      [
        { :long => 'css',  :short => 's', :argument => :none,
          :desc => ('subset: css -- ' <<
          'show diffs in css files between things (default, only option)')
        },
        { :long => 'content-to-output', :short => 'c', :argument => :none,
          :desc => 'show diff or patch content with output (default)'
        },
        { :long => 'proto-to-content', :short => 'p', :argument => :none,
          :desc => ("show diff or patch prototype with content\n"<<
                    (' '*22)+"(this would be for patching/altering nandoc)")
        },
        { :long => 'output-to-content', :short => 'C', :argument => :none,
          :desc => 'show diff or patch output with content (kind of weird)'
        },
        { :long => 'content-to-proto', :short => 'P', :argument => :none,
          :desc => 'show diff or patch content with proto (sure why not)'
        },
        { :long => 'patch', :short => 'Y', :argument => :none,
          :desc => 'apply the patch to the target (no undo!)'
        }
      ]
    end

    def run opts, args
      normalize_opts opts
      app_path = deduce_app_path_or_fail(args)
      src, dest = deduce_src_and_dest app_path, opts
      subset = deduce_subset opts
      go_diff src, dest, subset, app_path
    end

  private

    def go_diff *a
      src_path, dest_path = deduce_paths(*a)
      diff = NanDoc::DiffProxy.diff(src_path, dest_path)
      if diff.error?
        task_abort diff.error
      end
      if $stdout.tty? && NanDoc::Config.colorize?
        diff.colorize($stdout, :styles => NanDoc::Config.diff_stylesheet)
      else
        $stdout.puts diff.to_s
      end
    end

    def deduce_css_paths src, dest, app_path
      paths = [src, dest].map do |which|
        case which
          when :output;  app_path + '/output/css'
          when :content; app_path + '/content/css'
          when :proto;
          please_get_prototype_root_path(app_path)+'/content/css'
          else fail(
            "implement me: get #{which.to_s} path from #{src.inspect}"
          )
        end
      end
      paths
    end

    def deduce_paths src, dest, subset, app_path
      paths = case subset
        when :css; deduce_css_paths src, dest, app_path
        else; fail("unimplemented subset: #{subset}")
      end
      src_path, dest_path = paths
      assert_path "css source path",      src_path
      assert_path "css destination path", dest_path
      [src_path, dest_path]
    end

    def deduce_src_and_dest app_path, opts
      flag = exclusive_opt_flags(opts) do
        flags :content_to_output, :content_to_proto,
              :output_to_content, :proto_to_content
        default '-c', :content_to_output
      end
      /\A(.+)_to_(.+)\Z/ =~ flag.to_s or fail("no: #{flag}")
      src, dest = $1.to_sym, $2.to_sym
      [src, dest]
    end

    def deduce_subset opts
      flag = exclusive_opt_flags(opts) do
        flags :css
        default :css
      end
    end

    def please_get_prototype_root_path app_path
      config = parse_config_for_app_path app_path
      result = path_tardo(config, 'data_sources/[0]/site_prototype')
      if result.found?
        thing_in_config = result.value
        full_path = "proto/#{thing_in_config}"
        full_path
      else
        task_abort(
          result.error_message + " in " + config_path_for_app_path(app_path)
        )
      end
    end
  end
end
