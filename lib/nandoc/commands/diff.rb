require File.expand_path('../../support/diff-proxy.rb', __FILE__)
module NanDoc::Commands
  module AppCommandHelpers
    def deduce_app_path_or_fail args
      if args.any?
        deduce_app_path_from_args args
      else
        deduce_app_path_from_persistent_data
      end
    end
  private
    def deduce_app_path_from_args args
      if File.exist?(args.first)
        path = args.first
        unless path == persistent_get('last_app_path')
          persistent_set('last_app_path', path)
        end
        path
      else
        task_abort <<-D.gsub(/^  */,'')
          site path not found: #{args.first.inspect}
          usage: #{usage}
          #{invite_to_more_command_help}
        D
      end
    end
    def deduce_app_path_from_persistent_data
      if path = persistent_get('last_app_path')
        if File.exist?(path)
          path
        else
          persistent_set('last_app_path',false)
          task_abort <<-D.gsub(/^  */,'')
          previous site path is stale (#{path.inspect}) and no site provided
          usage: #{usage}
          #{invite_to_more_command_help}
          D
        end
      else
        task_abort(
        'no site path provided and no site path in persistent data file '<<
        "(#{NanDoc.dotfile_path})\n"<<
        <<-D.gsub(/^ */,'')
        usage: #{usage}
        #{invite_to_more_command_help}
        D
        )
      end
    end
  end
  class Diff < ::Cri::Command
    NanDoc.persistent_delegate_to(self) # empty_tmpdir(), file_utils()
    include NanDoc::CliCommandHelpers
    include AppCommandHelpers

    def name; 'diff' end

    def aliases; [ 'd' ] end

    def short_desc; 'maybe push and pull' end

    def long_desc
      <<-D.gsub(/\n +/,' ')
      (nanDoc hack) show diffs in css files, one day between any
      two of the three spots.
      D
    end

    def usage; "nandoc diff [(-c|)] [-o|-p] [-a] [<path>]" end

    def option_definitions
      [
        { :long => 'css', :short => 'c', :argument => :none,
          :desc => 'show diffs in css files between things'
        },
        { :long => 'output', :short => 'o', :argument => :none,
          :desc => 'show diff from output to content (patch content)'
        },
        { :long => 'proto', :short => 'p', :argument => :none,
          :desc => 'show diff from content to proto (patch proto)'
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
      $stderr.puts diff.command
      $stderr.puts "-----(above is stderr, below is stdout)--------"
      $stdout.puts diff.to_s
    end
    def deduce_paths src, dest, subset, app_path
      case subset
      when :css
        src_path =
          case src
          when :output; app_path + '/output/css'
          else fail("implement me: #{src}")
          end
        dest_path =
          case dest
          when :content; app_path + '/content/css'
          else fail("implement me: #{dest}")
          end
      else
        fail("implement me: #{subset}")
      end
      assert_path "css source path", src_path
      assert_path "css destination path", dest_path
      [src_path, dest_path]
    end
    def deduce_src_and_dest app_path, opts
      exclusive = [:output, :proto]
      has = exclusive & opts.keys
      src =
      case has.size
      when 0; :output
      when 1; has.first == :proto ? :content : has.first
      else
        task_abort <<-D.gsub(/^  */,'')
    #{exclusive.map{|x| "--#{x.to_s}"}.join(' and ')} are mutually exclusive.
        usage: #{usage}
        #{invite_to_more_command_help}
        D
      end
      dest =
      case src
      when :output; :content
      when :content; :proto
      else fail('oops')
      end
      [src, dest]
    end
    def deduce_subset opts
      opts[:css] ? :css : :css
    end
  end
end
