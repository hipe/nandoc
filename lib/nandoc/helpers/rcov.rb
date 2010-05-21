module NanDoc
  class RcovAgent
    include Singleton
    ::Treebis::PersistentDotfile.include_to(self,
      ['.rcov.persistent.json','../.rcov.persistent.json']
    )
    def last_percent
      (h = last_rcov and h['percent']) || nil
    end
    def last_sloc
      (h = last_rcov and h['sloc']) || nil
    end
    def last_rcov
      persistent_get('last_rcov')
    end
    def save_last_rcov_info  percent, num_files, num_lines, num_sloc
      persistent_set 'last_rcov', {
        'percent' => percent.to_f,
        'sloc'    => num_sloc.to_i
      }      
    end
  end  
  module Helpers
    module NanDocHelpers
      # experimental additions to nanDoc that can inject rcov info from
      # the last rcov into docs. We get SLOC count from this, yay!
      
      # @return nil or [Float] last percent
      def rcov_last_percentage
        RcovAgent.instance.last_percent
      end
      def rcov_last_percentage_pretty
        p = rcov_last_percentage || '??'
        "#{p}%"
      end
      # @return nil or [Fixnum] last sloc
      def rcov_last_sloc
        RcovAgent.instance.last_sloc
      end
      def rcov_last_sloc_pretty
        rcov_last_sloc || '??'
      end
    end
  end
end
