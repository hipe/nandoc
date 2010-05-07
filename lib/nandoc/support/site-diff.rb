require File.dirname(__FILE__)+'/diff-proxy.rb'

module NanDoc
  class SiteDiff
    #
    # This is a reworking of what's in site-merge (which doesn't really
    # do anything useful attotw, if it still even works.)
    # it's a wrapper around diff proxy that knows what folder(s) & file(s) we
    # do and don't want to take into account when showing a sitewide diff.
    # Specifically it's expected use is for comparing <my-site>/(* ~ output)
    # with its protoype.
    #

    include NanDoc::Config::Accessors   # file_utils()
    include NanDoc::PathTardo           # debug-ging e.g. hash_to_paths()
    NanDoc.persistent_delegate_to(self) # empty_tmpdir()
    include Treebis::DirAsHash          # dir_as_hash()
    include Treebis::Capture3           # capture3()

    def initialize src_path, dest_path
      @skip_these = %w(
        output
        tmp
        **/*.orig.rb
        **/*.diff
        treebis-task.rb
      )
      @src_path, @dst_path = src_path, dest_path
    end

    def get_diff_object
      file_utils.notice('comparing these:',
        "#{@src_path.inspect} -> #{@dst_path.inspect}"
      )
      src_hash = dir_as_hash(@src_path, :skip => @skip_these)
      dst_hash = dir_as_hash(@dst_path, :skip => @skip_these)
      dir = empty_tmpdir('site-diff')
      src_path = dir + '/a'
      dst_path = dir + '/b'
      hash_to_dir src_hash, src_path, file_utils
      hash_to_dir dst_hash, dst_path, file_utils
      diff = NanDoc::DiffProxy.diff(src_path, dst_path, :relative_to=>dir)
      diff
    end
  end
end
