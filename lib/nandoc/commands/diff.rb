support =  File.expand_path('../../support', __FILE__)
require support + '/diff-proxy.rb'
require support + '/path-tardo.rb'
require support + '/site-methods.rb'

module NanDoc::Commands
  class Diff < ::Cri::Command
    NanDoc.persistent_delegate_to(self) # persistent_set(), persistent_get()
    include NanDoc::Cli::CommandMethods
    include NanDoc::Cli::OptionMethods
    include NanDoc::PathTardo
    include NanDoc::SiteMethods

    def name; 'diff' end

    def aliases; [ 'd' ] end

    def short_desc
      "#{NanDoc::Config.option_prefix}maybe push and pull some stuff"
    end

    def long_desc
      <<-LONG_DESC.gsub(/\n +/,' ')
      Patch a subtree of <my-site>/content with the same subtree in
      <my-site>/output with (--content-to-output|-c). (default). Opposite
      direction with -C.

      Patch a subtree of <prototypes>/<the-prototype> with the same
      subtree of <my-site>/content with (--content-to-prototype|-p).
      (For patching nanDoc prototypes.) Opposite direction with -P.

      This operates on a subset of the indicated trees, for now either
      the css folders in <my-site>/output/ and <my-site>/content/ or the
      layout folders between the prototype and the <my-site>.  Indicate
      which with -s (css|layouts) (default: css)

      So, with this wierd chain, you can tweak your CSS, for example,
      in the generated output and then push these changes all the way back to
      the prototype with -cY and then -pY

      Or you can undo your changes pulling all the way back from the prototype
      with -PY and then -CY
      LONG_DESC
    end

    def usage;
    'nandoc diff [-c|-C|-p|-P] [-s (css|layouts|js|root)] [-Y [-b]] [<path>]'
    end

    def option_definitions
      pttp = 'pass-thru to patch. only for use with -Y'
      [ { :long => 'backup', :short => 'b', :argument=>:none,
          :desc => pttp
        },
        { :long => 'content-to-output', :short => 'c', :argument => :none,
          :desc => 'show diff or patch content with output (default)'
        },
        { :long => 'content-to-proto', :short => 'P', :argument => :none,
          :desc => 'show diff or patch content with proto (sure why not)'
        },
        { :long => 'dry-run',  :short => 'r', :argument => :none,
          :desc => pttp
        },
        { :long => 'output-to-content', :short => 'C', :argument => :none,
          :desc => 'show diff or patch output with content (kind of weird)'
        },
        { :long => 'patch', :short => 'Y', :argument => :none,
          :desc => 'apply the patch to the target (no undo!)'
        },
        { :long => 'proto-to-content', :short => 'p', :argument => :none,
          :desc => ("show diff or patch prototype with content\n"<<
                    (' '*22)+"(this would be for patching/altering nandoc)")
        },
        { :long => 'subset', :short => 's', :argument => :required,
          :desc => "'css' or 'layouts' or 'js' (default: css)"
        }
      ]
    end

    def run opts, args
      opts = normalize_opts opts
      site_path = deduce_site_path_or_fail(args)
      src, dest = deduce_src_and_dest site_path, opts
      subset = subsets.parse(opts)
      if opts[:patch] # @todo this doesn't belong here probably
        patch_opts = process_patch_opts(opts, src, dest, site_path)
        go_patch src, dest, subset, site_path, patch_opts
      else
        process_diff_opts(opts) and fail("no more opts for this guy")
        go_diff src, dest, subset, site_path
      end
    end

  private

    def deduce_root_paths src, dest, site_path
      @diff_method = :diff_root_subset
      path_src = deduce_subfolder_path site_path, src
      path_dst = deduce_subfolder_path site_path, dest
      if path_src == path_dst
        command_abort("source and destination paths are the same. "<<
        "did you forget -p or -P ?\nusage: #{usage}\n"<<
        invite_to_more_command_help)
      end
      [path_src, path_dst]
    end

    def deduce_subfolder_path site_path, which, sub=nil
      tox =
      case which
        when :output;  [site_path, sub ? 'output' : nil, sub]
        when :content; [site_path, sub ? 'content': nil, sub]
        when :proto;   [proto_path(site_path), sub ? 'content' : nil, sub]
        else fail(
          "implement me: get #{which.to_s} subpath")
      end
      File.join(tox.compact)
    end

    def deduce_subfolder_paths sub, src, dest, site_path
      paths = [src, dest].map do |which|
        deduce_subfolder_path site_path, which, sub
      end
      paths
    end

    def deduce_layout_paths src, dest, site_path
      if [src, dest].index(:output)
        command_abort "Sorry, it doesn't make sense to look at layout " <<
        "in output directory because there is none.\n" <<
        "Please use -P or -p to compare layout btwn proto and <my-site>.\n"<<
        "usage: #{usage}\n#{invite_to_more_command_help}"
      end
      paths = [src, dest].map do |which|
        case which
          when :content; site_path + '/layouts'
          when :proto;   proto_path(site_path)+'/layouts'
          else fail(
            "implement me: get #{which.to_s} path from #{src.inspect}")
        end
      end
      paths
    end

    def deduce_paths src, dest, subset, site_path
      paths = case subset
        when 'css';     deduce_subfolder_paths 'css', src, dest, site_path
        when 'layouts'; deduce_layout_paths src, dest, site_path
        when 'js';      deduce_subfolder_paths 'js', src, dest, site_path
        when 'root';    deduce_root_paths src, dest, site_path
        else; fail("unimplemented subset: #{subset}")
      end
      src_path, dest_path = paths
      command_path_assert "source path",      src_path
      command_path_assert "destination path", dest_path
      [src_path, dest_path]
    end

    def deduce_src_and_dest site_path, opts
      flag = exclusive_opt_flags(opts) do
        flags :content_to_output, :content_to_proto,
              :output_to_content, :proto_to_content
        default '-c', :content_to_output
      end
      /\A(.+)_to_(.+)\Z/ =~ flag.to_s or fail("no: #{flag}")
      src, dest = $1.to_sym, $2.to_sym
      [src, dest]
    end

    def diff_normal src_path, dest_path
      NanDoc::DiffProxy.diff(src_path, dest_path)
    end

    def diff_root_subset src, dest
      require File.expand_path('../../support/site-diff.rb', __FILE__)
      thing = NanDoc::SiteDiff.new(src, dest)
      thing.get_diff_object
    end

    def get_diff_object(*a)
      @diff_method = :diff_normal
      src_path, dest_path = deduce_paths(*a)
      diff = case @diff_method # no send() b/c trace stacks look dumb
        when :diff_normal;      diff_normal(src_path, dest_path)
        when :diff_root_subset; diff_root_subset(src_path, dest_path)
      end
      if diff.error?
        command_abort diff.error
      end
      diff
    end

    def go_diff(*a)
      diff = get_diff_object(*a)
      $stderr.puts diff.command
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

      # Make a tempdir and write the diff to a file
      tmpdir = empty_tmpdir('for-a-patch')
      Treebis::Task.new do
        notice 'command', diff.command
        write 'diff', diff.to_s
      end.on(tmpdir).run

      # Patch this sucker and pray we didn't mess up too badly
      Treebis::Task.new do
        from tmpdir
        apply 'diff', pass_thru
      end.on('.').run
    end

    def subsets
      cmd = self
      @subsets ||= option_enum.new do |oe|
        command cmd
        name :subset
        values %w(css layouts js root)
        default 'css'
      end
    end

    def proto_path site_path
      config = parse_config_for_site_path site_path
      result = path_tardo(config, 'data_sources/[0]/site_prototype')
      if result.found?
        thing_in_config = result.value
        full_path = NanDoc::Config.proto_path+"/#{thing_in_config}"
        full_path
      else
        command_abort(
          result.error_message + " in " + config_path_for_site_path(site_path)
        )
      end
    end

    PatchPassThru = [:backup, :dry_run, :directory]
    def process_diff_opts opts
      if (bad = opts.keys & PatchPassThru).any?
        bads = bad.map{|x| unnormalize_opt_key(x)}.join('and')
        command_abort "#{bads} cannot be used with diffing only patching.\n"<<
          "usage: #{usage}\n#{invite_to_more_command_help}"
      end
    end

    def process_patch_opts opts, src, dest, site_path
      keys = opts.keys & PatchPassThru
      switches = keys.map{|k| unnormalize_opt_key(k)}
      switch_h = Hash[switches.zip(Array.new(switches.size, ''))]
      switch_h['--posix'] = '' # always on else patches don't work
      process_patch_opts_for_directory switch_h, opts, src, dest, site_path
      {:pass_thru => switch_h }
    end

    #
    # when applying a root-based patch to a prototype we will have to change
    # directory to that prototype, just for when we apply the patch. and..?
    #
    def process_patch_opts_for_directory switch_h, opts, src, dest, site_path
      return unless opts[:subset] == 'root'
      if ! opts[:proto_to_content]
        command_abort("we need to test this for root patching for this target")
      end
      # it's not explicitly an available pass-thru option
      fail("huh?") if switch_h['--directory'] ||
        switch_h.keys.grep(/^-p\d+$/).any?
      proto = proto_path(site_path)
      # for a path like './a/Rules', we cd to the root of the proto, so we
      # want to disregard two levels of path context.
      switch_h['-p2'] = ''
      switch_h['--directory'] = proto
      nil
    end
  end
end
