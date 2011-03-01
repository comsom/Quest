# desc: エラー値の定義。   ... エラーが起きたらただちに qi が終わる、では困る。

class QError
  # s_eval は error が起きたらこれを返す。
  def initialize(msg)
    @msg = msg
  end
  def inspect
    '[' + @msg + ']'
  end
end

