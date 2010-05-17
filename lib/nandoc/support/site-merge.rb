require File.dirname(__FILE__)+'/diff-proxy.rb'

module NanDoc
  class SiteMerge
    include Treebis::DirAsHash
    include Treebis::Capture3
    NanDoc.persistent_delegate_to(self) # empty_tmpdir()

    def initialize site_creator
      @creator = site_creator
    end
    def site_merge opts, args
      existing_site_path = args.first
      command_abort("it's not exist: #{path}") unless
        File.exist?(existing_site_path)
      # nanoc writes to stdout so we do too, but here we want to write
      # to stderr these notices, and write the diff to stdout
      out, err, diff = capture3 do
        $stdout.puts(
        "#------------------ (this is for the merge hack:) -----------------")
        @tmpdir = empty_tmpdir('ridiculous')
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
end
