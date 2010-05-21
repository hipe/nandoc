module NanDoc::SpecDoc::Playback
  class SexpScanner
    def initialize sexp
      @sexp = sexp
      @offset = 0
      @last = @sexp.size - 1
    end
    def chimp arr
      arr.size == 1 ? arr.first : arr
    end
    def current
      @sexp[@offset]
    end
    def eos?
      @offset > @last
    end
    # if you set this, know what you are doing
    attr_accessor :offset
    def rest
      @sexp[@offset..-1]
    end
    attr_reader :sexp
    def scan a, *b
      current = self.current or return nil
      search = [a,*b]
      ret = nil
      if current[0..search.size-1] == search
        ret = current
        @offset += 1
      end
      ret
    end
    def scan_assert a, *b
      ret = scan(a, *b)
      if ! ret
        fail("expecting #{a.inspect} had #{current.inspect}")
      end
      ret
    end
    def skip_to_after *a, &b
      if b
        fail("can't use block and args") if a.any?
        skip_to_after_block(&b)
      else
        fail("must provide args or block") if a.empty?
        skip_to_after_vals(*a)
      end
    end
    def skip_to_after_assert *a, &b
      if a.empty? && b
        skip_to_after_block_assert(&b)
      elsif a.any? && ! b
        skip_to_after_vals_assert(*a)
      else
        fail("can't have both args and block or neither")
      end
    end
    def skip_to_after_block &b
      last = @sexp.length - 1
      idx = (@offset..last).find{ |idx| b.call(@sexp[idx]) }
      ret = idx || false
      ret
    end
    def skip_to_after_block_assert &b
      idx = skip_to_after_block(&b)
      if ! idx
        fail("#{b} never reached.")
      end
      idx
    end
    def skip_to_after_vals a, *b
      search = [a, *b]
      last = search.size - 1
      last_node = @sexp.size - 1;
      idx = (@offset..last_node).find{ |idx| @sexp[idx][0..last] == search }
      ret = false
      if idx
        @offset = idx + 1
        ret = @offset
      end
      ret
    end
    def skip_to_after_vals_assert *a, &b
      idx = skip_to_after_vals(*a)
      if ! idx
        search = [a, *b]
        last = search.size - 1
        nn = @sexp.select{ |n| n[0..last] == search }
        nn = nn.map{ |n| chimp(n[1..-1]).inspect }
        fail("#{chimp(search).inspect} not found. had:(#{nn.join(', ')})")
      end
      idx
    end
  end
end
