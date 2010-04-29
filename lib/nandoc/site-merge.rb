module NanDoc
  class SiteMerge
    include Treebis::DirAsHash
    include Treebis::Capture3
    def initialize site_creator
      @creator = site_creator
    end
    def site_merge opts, args
      existing_site_path = args.first
      task_abort("it's not exist: #{path}") unless
        File.exist?(existing_site_path)
      # nanoc writes to stdout so we do too, but here we want to write
      # to stderr these notices, and write the diff to stdout
      out, err, diff = capture3 do
        $stdout.puts(
        "#------------------ (this is for the merge hack:) -----------------")
        @tmpdir = @creator.empty_tmpdir('ridiculous')
        existing_subset_path = temp_site_subset(existing_site_path)
        generated_site_path  = temp_generated_site opts
        order = [existing_subset_path, generated_site_path]
        order.reverse! if opts[:merge_hack_reverse]
        diff = DiffProxy.diff(order[0], order[1], :relative_to => @tmpdir)
        # you could delete the tempdirs now. we will leave them there
        diff
      end
      fail("hack failed: #{err.inspect}") unless err.empty?
      $stderr.puts out # write out to err here
      $stderr.puts diff.command
      $stderr.puts <<-HERE.gsub(/^ +/,'')
      #---------------- (above is stderr, below is stdout) ------------------
      HERE
      $stdout.puts diff.to_s
      diff
    end
  private
    def temp_site_subset path
      subset_in_memory = dir_as_hash(path, :skip=>['output'])
      @file_utils = NanDoc::Config.file_utils
      subset_on_disk = @tmpdir+'/user-site'
      hash_to_dir(subset_in_memory, subset_on_disk, @file_utils)
      subset_on_disk
    end
    def temp_generated_site opts
      put_it_here = @tmpdir+'/generated-site'
      chops = opts.dup
      chops.delete(:datasource)
      @creator.run(chops, [put_it_here], :_merge=>false)
      remove_output_directory(put_it_here)
      put_it_here
    end
    def remove_output_directory put_it_here
      dir = put_it_here + '/output'
      fail("fail") unless File.directory?(dir)
      fail("fail") unless Dir[dir+'/*'].empty?
      @file_utils.remove_entry_secure(dir)
    end
  end

  module DiffProxy
    include Treebis::Sopen2
    extend self
    def diff path_a, path_b, opts={}
      fail('no') unless File.exist?(path_a) && File.exist?(path_b)
      rel_to = opts.delete(:relative_to)
      path_a, path_b = relativize(rel_to, path_a, path_b) if rel_to
      opts = {'--unified=3'=>nil, '--recursive'=>nil}.merge(opts)
      args = ['diff'] + opts.each.map.flatten.compact + [path_a, path_b]
      out = err = nil
      block = proc do
        out, err = sopen2(*args)
      end
      if rel_to
        FileUtils.cd(rel_to, :verbose=>true, &block)
      else
        block.call
      end
      diff = Diff.new(out, err, args)
      if diff.error?
        return fail(diff.full_error_message){|f| f.diff = diff }
      end
      diff
    end
  private
    def fail(*a, &b)
      raise Fail.new(*a, &b)
    end
    def relativize base, path_a, path_b
      fail("KISS") unless [0,0]==[path_a, path_b].map{|x| x.index(base)}
      tail_a, tail_b = [path_a, path_b].map{|x| '.'+x[base.length..-1]}
      [tail_a, tail_b]
    end
    class Diff
      def initialize out, err, args
        @out = out
        @error = err
        @args = args
      end
      attr_reader :error
      def command
        Shellwords.join(@args)
      end
      def error?; ! @error.empty? end
      def full_error_message
        "diff failed: #{command}\ngot error: #{error}"
      end
      def ok?; ! error? end
      def to_s
        @out
      end
    end
    class Fail < RuntimeError;
      def initialize(*a,&b)
        super(*a)
        yield self if block_given?
      end
      attr_accessor :diff
    end
  end
end
