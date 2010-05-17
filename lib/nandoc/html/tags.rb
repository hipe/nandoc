module NanDoc::Html
  class Tags

    def initialize
      @current = nil
      @content = []
    end

    attr_reader :content
    attr_reader :current

    def push_raw str
      flush if @current
      @content.push str
    end

    def push_smart name, classes, content
      tag = normalize_tag(name, classes)
      if @current != tag
        flush if @current
        @current = tag
        @content.push render_open_tag(tag)
      end
      @content.push content
      nil
    end

    def push_tag_now name, classes, content
      tag = normalize_tag(name, classes)
      @content.push render_open_tag(tag)
      @content.push content
      @content.push render_close_tag(tag)
      nil
    end

    def to_html
      flush if @current
      @content.join('')
    end

  private

    def flush
      if @current
        @content.push render_close_tag(@current)
        @current = nil
      end
    end

    def render_close_tag tag
      name = tag.first
      "</#{name}>"
    end

    def render_open_tag tag
      name, classes = tag
      "<#{name} class='#{classes.join(' ')}'>"
    end

    def normalize_tag name, classes
      classes = classes.kind_of?(Array) ? classes : [classes]
      [name, classes]
    end
  end
end
