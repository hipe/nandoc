require 'diff/lcs'
require 'nandoc/support/diff-to-string'

module MiniTest
  module Assertions

    ##
    # Fails unless <tt>exp == act</tt>.
    # On failure use diff to show the diff, if +exp+
    # and +act+ are of the same class and
    #

    def assert_no_diff exp, act, msg=nil, opts={}
      if opts.kind_of?(String)
        opts = {:sep=>opts}
      end
      opts = {:sep=>"\n"}.merge(opts)
      msg = message(msg) do
        exp_kind, act_kind = [exp,act].map do |x|
          [String, Array].detect{|c| x.kind_of?(c)}
        end
        if exp_kind != act_kind
          "Expecting #{exp_kind.inspect} had #{act_kind.inspect}"
        elsif exp_kind.nil?
          "Will only do diff for strings and arrays, not #{exp.class}"
        else
          differ = DiffToString.gitlike!
          if exp_kind == String
            use_exp = exp.split(opts[:sep], -1)
            use_act = act.split(opts[:sep], -1)
          else
            use_exp = exp
            use_act = act
          end
          diff = Diff::LCS.diff(use_exp, use_act)
          if diff.empty?
            fail("test test fail -- never expecting empty diff here")
          else
            differ.arr1 = use_exp
            differ.arr2 = use_act # awful
            differ.diff_to_str(diff, :context=>3)
          end
        end
      end
      if re = opts[:ignoring]
        exp, act = [exp, act].map do |str|
          str.kind_of?(String) ? str.gsub(re, re.source) : str
        end
      end
      assert(exp == act, msg)
    end
  end
end
