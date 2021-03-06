require 'nandoc/cli'

module NanDoc

  class DataSource < ::Nanoc3::DataSources::FilesystemUnified
    #
    # Make a Nanoc3 DataSource class as necessary to A) pull in
    # content files that exist outside of the <my-site>/content directory and
    # B) allow one of those files to act as the root index page for the
    # generated site, as indicated by config.yaml. and C) rescue orphan
    # files that have a parent directory but no parent file, and
    # D) to see as text files without an extension (e.g. README)
    #
    # Some of the hacks in this file are the worst in the whole project. @todo
    #

    include Cli::CommandMethods # command_abort

    def initialize *a
      super(*a)

      # hack to see as text files without an extension!
      unless @site.config[:text_extensions].include?(nil)
        @site.config[:text_extensions].unshift(nil)
      end
      @hax_filename_for_last = nil
      @config = a.last
      @basenames = @config[:source_file_basenames] or
        fail("must have source_file_basenames in config.yaml  "<<
          "for nandoc to work."
        )
      @hax_mode = false # this gets turned on when we are doing s/thing weird
      @hax_root_found = false
    end

    #
    # the content filename for ../README is ../README
    #
    def filename_for(base_filename, ext)
      return super unless @hax_mode && ext.nil?
      if @hax_filename_for_last != base_filename
        @hax_filename_for_last = base_filename
        return super
      else
        base_filename
      end
    end


    #
    # Hack the items returned by this datasource object to include also
    # files outside of the <my-site>/content directory, e.g. README.md
    # or README/**/*, NEWS.md, based on settings in the config.
    #
    # Rescue orphan nodes with no parent page somehow.
    #
    def items
      _ = Nanoc3::Item # autoload it now for easier step debug-ging
      these = super
      dot_dot_names = @basenames.map{|x| "../#{x}"}
      @hax_mode = true
      additional = dot_dot_names.map do |basename|
        if File.file?(basename) # was different
          load_objects(basename, 'item', Nanoc3::Item)
        else
          load_objects(basename, 'item', Nanoc3::Item)
        end
      end.compact.flatten(1)
      @hax_mode = false
      error_for_no_files(dot_dot_names) if additional.empty?
      res = these + additional
      orphan_rescue(res)
      res
    end

  private

    #
    # a hook to grab the folder name that later gets stripped out
    # also a supremely ugly hack to get e.g. ../README.md
    #
    def all_split_files_in dir_name
      return super unless @hax_mode
      @hax_last_dirname = dir_name
      ret = super
      lone_files = ["#{dir_name}.md", dir_name]
      lone_file = find_first_file(lone_files)
      if lone_file  # e.g. '../README.md', 'README'
        @hax_last_filename = lone_file.dup
        class << lone_file
          #
          # supremely fragile hack:
          # make it so that it ignores the next + operation in the first
          # line of Nanoc3::DataSources::Filesystem#all_split_files_in()
          # this is shorter and easier than overriding and rewring
          # the above function but it is a supreme haxie guaranteed to fail
          # one day!!!
          #
          def + _; self end
        end
        other = super(lone_file)
        ret.merge!(other)
      end
      ret
    end

    # removed old deal_with_index_page_children in e7bf7ee

    #
    # We crap out if we didn't find any weird files because after all
    # this is NanDoc.
    #
    def error_for_no_files files
      command_abort <<-HERE.gsub(/\n +/,"\n").strip
      No matching content file(s) found at or under (#{files.join(', ')})
      from here. (This corresponds to the 'source_file_basenames' setting in
      config.yaml.)  Did you generate the NanDoc site in the right directory?
      HERE
    end

    def find_first_file names
      names.detect{ |n| File.file?(n) }
    end

    #
    # We don't seem to want any urls with uppercase characters in them
    # because .. not sure.  But the rsync by default downcases our files.
    # It's probably a good habbit to do this.  If we want to accept a variety
    # of casing with our server that's ok but internally we should keep it consistent
    # and simple.  (This causes gotchas sometimes when moving from a case-insensitive
    # filesystem like that of OSX to a case-sensitive one like that of debian.)
    # The titles of items, on the other hand ...
    #
    def identifier_normalize identifier
      if /[A-Z]/ =~ identifier
        use_identifier = identifier.downcase
      else
        use_identifier = identifier
      end
      use_identifier
    end

    #
    # more crazy hacks - normally content/foo/bar.html => "/foo/bar/" but
    # for this case we don't want to have stripped the containing folder,
    # *and* we try to hack it so that it's laid alongside content in
    # the content folder for the final site. (or not, here)
    # also we need to make sure one item is '/' somehow
    # @todo unhack this whole page
    #
    # @todo some stuff that happens in the orphanage should happen here
    # instead
    #
    def identifier_for_filename fn
      return super unless @hax_mode
      if 'md' == fn # there has to be a better way :(
        no_dot_dot = dot_dot_strip_assert(@hax_last_filename)
        if no_dot_dot == @config[:use_as_main_index] # 'README.md'
          identifier = '/' # overwrite the index.html generated by nandoc!
        else
          # '../README.md' => 'README.md' => '/README/'
          identifier = super(no_dot_dot)
        end
      else
        if fn
          if dot_dot_has?(fn)
            fail("fix this -- should never have dot dot name here: #{hn}")
          end
          identifier = super(fn)
        else
          identifier = dot_dot_strip_assert(@hax_last_dirname)+'/'
        end
      end
      # before we get to resuce orphans we need to make sure we have
      # resolved some file as a site root.  First one wins.
      if ! @hax_root_found
        shorter = slash_strip_assert(identifier)
        if @basenames.include?(shorter)
          @hax_root_found = true
          identifier = '/'
        end
      end
      use_identifier = identifier_normalize(identifier)
      use_identifier
    end

    #
    # A) Experimentally generate index pages for child nodes without them
    # B) merge many filesystem roots to one docroot (hack!) per 'basenames'
    # (undefined on name collision)
    #
    def orphan_rescue items
      require 'nandoc/support/orphanage.rb'
      Orphanage.rescue_orphans(@config, items)
    end

  private

    module ItemMethods
      # must have @items.  make public if u need it

      def find_parent item_identifier
        parent_path = parent_identifier(item_identifier)
        parent = @items.find { |p| p.identifier == parent_path }
        parent
      end
      def identifier_bare_rootname identifier
        /\A\/([^\/]+)\// =~ identifier and $1
      end
      def identifier_bare_rootname_assert identifier
        identifier_bare_rootname(identifier) or
          fail("hack fail: couldn't find rootname for #{identifier.inspect}")
      end
      # exactly one leading and one trailing slash
      def slash_strip identifier
        /\A\/(.+)\/\Z/ =~ identifier and $1
      end
      def slash_strip_assert identifier
        slash_strip(identifier) or fail("hack fail: #{identifier}")
      end
      def parent_identifier identifier
        identifier.sub(/[^\/]+\/$/, '')
      end
      def site_root
        @site_root ||= @items.find{|x| x.identifier == '/' }
      end
      def dot_dot_has? str
        /\A\.\./ =~ str
      end
      def dot_dot_strip str
        /\A\.\.(.*)\Z/ =~ str and $1
      end
      def dot_dot_strip_assert str
        dot_dot_strip(str) or
          fail("hack fail: no leading dot dot: #{str.inspect}")
      end
    end
    include ItemMethods
  end
end
