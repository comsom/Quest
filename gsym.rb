# desc: 非終端記号と終端記号のクラス定義。

# gsym :abbrev: grammatical symbol 文法記号

class NonTerminal
  attr_reader :gsid # '==' の定義の中でしか使ってない。
  def initialize(gsid)
    @gsid = gsid           # abbrev: gsym id
  end
  def is_nonterminal?
    true
  end
  def is_terminal?
    false
  end
  def inspect
    @gsid.to_s
  end
  def ==(x)
    (x.class == NonTerminal) and (@gsid == x.gsid)
  end
  # vvv hash @@redposs in CalcPoss でのキーの同一性判定のための再定義 vvv
  # Marshal を使う ... というわけで定義。
  def eql?(x)
    (x.class == NonTerminal) and (@gsid == x.gsid)
  end
  def hash
    @gsid.to_i
  end
end

class Terminal
  attr_reader :gsid # '==' の定義の中でしか使ってない。
  attr_reader :val  # 解析木を見て何かするときに使う。
  def initialize(gsid, val=nil)
    @gsid  = gsid
    @val   = val
  end
  def gsym
    self
  end
  def is_nonterminal?
    false
  end
  def is_terminal?
    true
  end
  def inspect
    @gsid.to_s
  end
  def ==(x)
    (x.class == Terminal) and (@gsid == x.gsid)
  end
  # vvv hash @@redposs in CalcPoss でのキーの同一性判定のための再定義 vvv
  def eql?(x)
    (x.class == Terminal) and (@gsid == x.gsid)
  end
  def hash
    @gsid.to_i
  end
end

