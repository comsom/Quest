# desc: 複数の *.rb が使う Array method が現れたので、
# desc: そういう Array method だけ抜き出してここにまとめておく。

# methods used by fparser.rb and redposs.rb

class Array
  def concatall(&proc)
    # self (Array)の各要素に対し Array を返す proc を適用して、
    # 帰ってきた Array たちを + でつなげたものを返す。
    self.inject([]) {|acc,x| acc + proc.call(x) }
  end
  def setminus(set) # for: firstnts_inner
    # 引き算。 self から set を引く。
    self.omit{|x| set.include?(x) }
  end
  def omit(&pred)
    # delete_if は破壊的であるため、破壊的でないメソッドを作る。
    self.select{|x| not pred.call(x) }
  end
end




