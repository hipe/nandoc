module NanDoc
  class DataSource # reopen, not really necessary
    class Orphanage
      #
      # @api private implementation for experimental orphan_rescue()
      #
      include ItemMethods
      class << self
        def rescue_orphans config, items
          new(config, items).rescue_orphans
        end
        private :new
      end

      def rescue_orphans
        fail("must have site root to continue hacking") unless site_root
        items = @items.map # we are going to add to it in loop below
        items.each do |item|
          next unless is_orphan? item
          id = item.identifier
          parent_id = parent_identifier(id)
          bare_root = identifier_bare_rootname_assert(id)
          bare_parent = slash_strip_assert(parent_id)
          new_id = nil
          @renamer = nil
          if @basenames.include?(bare_root)
            # then we need to hack a rename to the identifier
            @renamer = /\A\/#{Regexp.escape(bare_root)}\/(.+)\Z/
            new_id = rename(id)
          end
          if (!new_id || bare_parent!=bare_root) && is_orphan?(item, new_id)
            make_surrogate_parent parent_id
          end
          item.identifier = new_id if new_id
        end
      end
    private
      def initialize config, items
        @basenames = config[:source_file_basenames] || []
        @items = items
      end

      def is_orphan? item, using_identifier=nil
        item.nandoc_content_leaf? or return false
        using_identifier ||= item.identifier
        parent = find_parent using_identifier
        parent.nil? && using_identifier != '/'
      end

      def make_surrogate_parent parent_id
        use_id = @renamer ? rename(parent_id) : parent_id
        use_path = @renamer ? "../#{parent_id}" : parent_id
        content = surrogate_content
        fake_parent = Nanoc3::Item.new(
          content,
          {:filename => use_path, :content_filename => use_path },
          use_id
        )
        @items.unshift(fake_parent)
      end

      # very private
      def rename str
        @renamer =~ str or
          fail("rename fail: #{str.inspect} against #{@renamer}")
        renamed = "/#{$1}"
        renamed
      end

      def surrogate_content
        @surrogate_content ||= begin
          File.read(NanDoc::Config.orphan_surrogate_filename)
        end
      end
    end
  end
end
