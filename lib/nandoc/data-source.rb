module NanDoc
  class DataSource < ::Nanoc3::DataSources::FilesystemUnified
    def initialize *a
      super(*a)
      config = a.last
      @hax_mode = false
      @source_file_basenames = config[:source_file_basenames]
    end

    #
    # hack the items returned by this datasource object to include also
    # files outside of the <my-site>/content directory, e.g. README.md
    # or README/**/*, NEWS.md, based on settings in the config.
    #
    def items
      _ = Nanoc3::Item # autoload it now for easier step debugging
      these = super
      dot_dot_names = @source_file_basenames.map{|x| "../#{x}"}
      @hax_mode = true
      additional = dot_dot_names.map do |basename|
        load_objects(basename, 'item', Nanoc3::Item)
      end.flatten(1)
      @hax_mode = false
      these + additional
    end

  private

    #
    # a hook to grab the folder name that later gets stripped out
    # also a supremely ugly hack to get e.g. ../README.md
    #
    def all_split_files_in dir_name
      return super unless @hax_mode
      @hax_last_dir_name = dir_name
      ret = super
      lone_file = "#{dir_name}.md"
      if File.exist?(lone_file) # e.g. '../README.md'
        @hax_last_filename = lone_file.dup
        class << lone_file
          # make it so that it ignores the next + operation in the first
          # line of Nanoc3::DataSources::Filesystem#all_split_files_in()
          # supreme haxie!
          def + _; self end
        end
        other = super(lone_file)
        ret.merge!(other)
      end
      ret
    end

    #
    # more crazy hacks - normally content/foo/bar.html blah blah, but
    # for this case we don't want to have stripped the containing folder,
    # *and* we hack it so that it's laid alongside (@todo) content in
    # the content folder for the final site.
    #
    def identifier_for_filename fn
      return super unless @hax_mode
      if 'md' == fn # there has to be a better way :(
        /\A\.\.(.*)\Z/ =~ @hax_last_filename or fail('hack fail 2')
        identifier = super($1) # '../README.md' => '/README.md' => '/README'
      else
        /\A\.\.(.*)\Z/ =~ @hax_last_dir_name or fail('hack fail 2')
        without = super(fn)
        identifier = "#{$1}#{without}"
      end
      identifier
    end
  end
end
