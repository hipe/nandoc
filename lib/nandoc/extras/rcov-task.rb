require 'nandoc' unless Object.const_defined?('NanDoc')
require 'open3'
require 'singleton'
require 'rcov/rcovtask'

module NanDoc
  class RcovTask < ::Rcov::RcovTask
    # copy-paste from parent and modify
    def define
      lib_path = @libs.join(File::PATH_SEPARATOR)
      actual_name = Hash === name ? name.keys.first : name
      unless Rake.application.last_comment
        desc "Analyze code coverage with tests" +
          (@name==:rcov ? "" : " for #{actual_name}")
      end
      task @name do
        run_code = ''

        RakeFileUtils.verbose(@verbose) do
          run_code =
          case rcov_path
          when nil, ''
            "-S rcov"
          else %!"#{rcov_path}"!
          end
          ruby_opts = @ruby_opts.clone
          ruby_opts.push( "-I#{lib_path}" )
          ruby_opts.push run_code
          ruby_opts.push( "-w" ) if @warning
          command = ruby_opts.join(" ") + " " + option_list +
            %[ -o "#{@output_dir}" ] +
            file_list.collect { |fn| %["#{fn}"] }.join(' ')
          out, err = nil, nil
          ruby_command = "ruby #{command}"
          Open3.popen3(ruby_command) do |ins, outs, errs|
            out = outs.read
            err = errs.read
          end
          puts err # just debugging junk from our tests
          process_output out
        end
      end

      desc "Remove rcov products for #{actual_name}"
      task paste("clobber_", actual_name) do
        rm_r @output_dir rescue nil
      end

      clobber_task = paste("clobber_", actual_name)
      task :clobber => [clobber_task]

      task actual_name => clobber_task
      self
    end
  private
    def process_output out
      $stdout.puts out  # output it no matter what
      re = /\A(\d+\.\d)%   (\d+) file\(s\)   (\d+) Lines   (\d+) LOC\Z/
      last_line = out.split("\n").last
      re =~ last_line or fail("failed to match last line against re:\n"<<
        "last line: #{last_line.inspect}\nre: #{re.source}"
      )
      percent, num_files, num_lines, num_sloc = $~.captures
      RcovAgent.instance.save_last_rcov_info(
        percent, num_files, num_lines, num_sloc
      )
    end
  end
end
