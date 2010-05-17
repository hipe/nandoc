require 'nandoc/support/string-methods'

module NanDoc::Cli::OptionMethods
  class OptionEnum

    # @todo are we using this?

    include NanDoc::StringMethods # oxford_comma

    def initialize(&block)
      instance_eval(&block)
    end
    def command cmd
      @command = cmd
    end
    def default str
      @default = str
    end
    def name name
      @name = name
    end
    def parse opts
      found = nil
      if opts.key?(@name)
        v = opts[@name]
        re = /\A#{Regexp.escape(v)}/
        founds = @values.grep(re)
        case founds.size
          when 0; invalid(v)
          when 1; found = founds.first
          else found = founds.detect{|f| f==v} or too_many(founds)
        end
      elsif(@default)
        found = @default
      else
        found = nil
      end
      opts[@name] = found if found # normalize short versions
      found
    end
    def values *v
      v = v.first if v.size==1 && Array === v
      @values = v
    end
  private
    def coda
      "usage: #{@command.usage}\n#{@command.invite_to_more_command_help}"
    end
    def invalid val
      @command.command_abort("invalid value #{val.inspect} for "<<
        "#{long_name}. #{valid_values_are}\n#{coda}")
    end
    def long_name
      unnormalize_opt_key(@name)
    end
    def too_many these
      @command.command_abort("did you mean " <<
        oxford_comma(these,' or ', &quoted)<<" for #{long_name}?\n#{coda}")
    end
    def valid_values_are
      "valid values are " << oxford_comma(@values,&quoted)
    end
  end
end
