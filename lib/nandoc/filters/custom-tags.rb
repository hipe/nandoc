module NanDoc::Filters
  class CustomTagsClass < Array
    def register_class cls
      unshift cls
    end
    def change_item_content content
      each do |cls|
        if cls =~ content
          tag_filter = cls.new
          new_content = tag_filter.run(content)
          content.replace(new_content)
        end
      end
      content
    end
  end

  CustomTags = CustomTagsClass.new
end
