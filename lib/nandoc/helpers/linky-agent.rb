module NanDoc
  class LinkyAgent
    include Singleton
    attr_accessor :context
    Daterz = {
      :javascript => {
        :ext => '.js',
        :head => '/js/',
        :off => :'javascripts-off',
        :plural => :javascripts,
        :re  => /\.js\Z/
      },
      :stylesheet => {
        :ext => '.css',
        :head => '/css/',
        :off => :'stylesheets-off',
        :plural => :stylesheets,
        :re  => /\.css\Z/
      }
    }
    def javascripts whitelist
      don_johnson :javascript, whitelist
    end
    def stylesheets whitelist
      don_johnson :stylesheet, whitelist
    end
  private
    def don_johnson which, whitelist
      item = self.send(:item)
      attrs = item.attributes
      meta = Daterz[which]
      list = (attrs[which] && [attrs[which]]) || attrs[meta[:plural]] || []
      self_actualized = list.map do |url|
        if url == 'self'
          meta[:head] + File.basename(item.path) + meta[:ext]
        elsif meta[:re] =~ url
          url
        else
          meta[:head] + url + meta[:ext]
        end
      end
      blacklist = attrs[meta[:off]] || []
      self_actualized -= blacklist
      whitelist -= blacklist # yes
      self_actualized.concat whitelist # order is important
      self_actualized
    end
    def item
      @context.item
    end
  end
  module Helpers
    module NanDocHelpers
      def linky_agent
        herkemer = NanDoc::LinkyAgent.instance
        herkemer.context = self
        herkemer
      end
    end
  end
end
