require File.dirname(__FILE__)+'/regexp-enhance.rb'

module NanDoc
  class Regexp < ::Regexp
    def initialize re, *names
      super(re)
      RegexpEnhance.to(self) do |me|
        me.names(*names) if names.any?
      end
    end
  end
end
