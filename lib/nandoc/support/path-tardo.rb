module NanDoc
  module PathTardo
    #
    # This is like a really basic xpath for data structures
    # that are composed of arrays and hashes
    #
    def tardo_array_index str
      /\A\[(-?\d+)\]\Z/ =~ str ? $1.to_i : nil
    end
    module_function :tardo_array_index

    def path_tardo hash_or_array, path_tardo, prefix = ''
      /\A([^\/]+)(?:\/(.+))?\Z/ =~ path_tardo or
        fail("no parse: #{path_tardo}")
      head, tail = $1, $2
      value = nil
      found = nil
      if idx = tardo_array_index(head)
        if idx > 0 && idx >= hash_or_array.size
          found = false
        elsif idx < 0 && (idx*-1) > hash_or_array.size
          found = false
        else
          found = true
          value = hash_or_array.slice(idx)
        end
      else
        if hash_or_array.key?(head)
          found = true
          value = hash_or_array[head]
        else
          found = false
        end
      end
      if ! found
        Tardo::NotFound.new(prefix, head, hash_or_array)
      elsif tail
        local_full_path =
          [ prefix.empty? ? nil : prefix, head ].compact.join('/')
        path_tardo(value, tail, local_full_path)
      else
        Tardo::Found.new(value)
      end
    end
    module Tardo
      class NotFound < Struct.new(:prefix, :head, :hash_or_array)
        def found?; false end
        def error_message
          sub_msg =
          if idx = PathTardo.tardo_array_index(head)
            "#{idx} is a nonexistant offset"
          else
            "a \"#{head}\" key does not exist"
          end
          context_msg =
          if prefix.empty?
            nil
          elsif hash_or_array.kind_of?(Array)
            "in \"#{prefix}\" array,"
          else
            "in hash \"#{prefix}\","
          end
          msg = [context_msg, sub_msg].compact.join(' ')
          msg
        end
      end
      class Found < Struct.new(:value)
        def found?; true end
      end
    end
  end
end
