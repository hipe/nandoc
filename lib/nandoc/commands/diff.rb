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
      Patch a subtree of <my-site>/content with the same subtree in
      <my-site>/output with (--content-to-output|-c). (default). Opposite
      direction with -C.

      Patch a subtree of <prototypes>/<the-prototype> with the same
      subtree of <my-site>/content with (--content-to-prototype|-p).
      (For patching nanDoc prototypes.) Opposite direction with -P.

      This operates on a subset of the indicated trees, for now only the files
      in the 'css/' folder. (This is what the --css option is for but for now
      it is the default and the only option so it is not necessary to
      indicate.)

      So, with this wierd chain, you can tweak your CSS, for example,
      in the generated output and then push these changes all the way back to
      the prototype with -cY and then -pY

      Or you can undo your changes pulling all the way back from the prototype
      with -PY and then -CY
      LONG_DESC
    end

    def usage; "nandoc diff [-c|-C|-p|-P] [--css|] [-Y [-b]] [<path>]" end

    def option_definitions
      [ { :long => 'backup', :short => 'b', :argument=>:none,
          :desc => 'when applying patches, makes backups. see `patch -b`. '<<
                   'This is only for use with -Y'
        },
        { :long => 'css',  :short => 's', :argument => :none,
          :desc => 'subset: css -- ' <<
          'show diffs in css files between things (default, only option)'
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
      opts = normalize_opts opts
      app_path = deduce_app_path_or_fail(args)
      src, dest = deduce_src_and_dest app_path, opts
      subset = deduce_subset opts
      if opts[:patch]
        patch_opts = process_patch_opts(opts)
        go_patch src, dest, subset, app_path, patch_opts
      else
        process_diff_opts(opts) and fail("no more opts for this guy")
        go_diff src, dest, subset, app_path
      end
    end

  private

    def get_diff_object(*a)
      src_path, dest_path = deduce_paths(*a)
      diff = NanDoc::DiffProxy.diff(src_path, dest_path)
      if diff.error?
        task_abort diff.error
      end
      diff
    end

    def go_diff(*a)
      diff = get_diff_object(*a)
      if $stdout.tty? && NanDoc::Config.colorize?
        diff.colorize($stdout, :styles => NanDoc::Config.diff_stylesheet)
      else
        $stdout.puts diff.to_s
      end
    end

    def go_patch *a
      patch_opts = a.pop
      pass_thru = patch_opts[:pass_thru] or fail('suxxorz')
      diff = get_diff_object(*a)
      task_abort("subset not yes supported: %s" %
        unnormalize_opt_key(@subset) ) unless @subset == :css

      # Make a tempdir and write the diff to a file
      tmpdir = empty_tmpdir('for-a-patch')
      Treebis::Task.new do
        write 'diff', diff.to_s
      end.on(tmpdir).run

      # Patch this sucker and pray we didn't mess up too badly
      Treebis::Task.new do
        from tmpdir
        apply 'diff', pass_thru
      end.on('.').run
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
      @subset = flag
      flag
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

    def process_diff_opts opts
      task_abort "--backup cannot be used with diffing only patching.\n"<<
      "usage: #{usage}\n#{invite_to_more_command_help}" if opts[:backup]
      nil
    end

    def process_patch_opts opts
      {:pass_thru => opts[:backup] ? {'--backup'=>''} : {}}
    end
  end
end
