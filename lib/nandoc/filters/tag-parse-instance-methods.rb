module NanDoc::Filters
  module TagParseInstanceMethods
    def unquote str
      case str
        when /\A'(.*)'\Z/ ; $1
        when /\A"(.*)"\Z/ ; $1
        else str
      end
    end
  end
end
