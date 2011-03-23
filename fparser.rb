# desc: fparser 構文解析器

require File.expand_path('../arraymethods', __FILE__) # 'arraymethods'
require File.expand_path('../qerror', __FILE__)       # 'qerror'

module Parser

  #-----------------------------------------------------------------------------
  # set_grammar!
  #-----------------------------------------------------------------------------
  # def get_redposs # @@redposs の test のための method : 外から @@redposs を見る。
  #   @@redposs
  # end
  def set_grammar!(rs,ss,rp)
    @@ruleset      = rs
    @@start_symbol = ss
    # ^^^以上が grammar を成す。以下はそれに対応する redposs である。
    @@redposs      = rp         # abbrev: reduction possibility 還元可能性
  end

  #-----------------------------------------------------------------------------
  # parse
  #-----------------------------------------------------------------------------
  def parse(tokenseq)
    tokenseq.inject([Poss.new([Root.new])]) {|poss_ary, token|
      pa = calc_poss_ary( poss_ary.map{|poss| Poss.new( poss + [token] ) } )
      return QError.new('Parse error : token : ' + token.inspect) if pa.empty?
      pa
    }
  end
  # - poss :abbrev: possibility 可能性
  def calc_poss_ary(poss_ary)
    poss_ary.omit{|poss| poss.root.completed? }.concatall {|poss|
      calc_poss(poss)
    }
  end
  
  #-----------------------------------------------------------------------------
  # calc_poss
  #-----------------------------------------------------------------------------
  def calc_poss(poss)
    if poss[-2].redtar.is_nonterminal? # abbrev: reduction target 還元目標
      # 還元可能性の生成(とその後の処理)
      @@redposs[poss[-2].redtar][poss[-1].gsym].concatall {|rule|
        new_poss = poss[0...-1] << Branch.new(rule, [poss[-1]])
        # 回収可能性の生成(とその後の処理)
        collectposses_then_postprocess(new_poss)
      }
    elsif poss[-2].redtar.is_terminal?
      # 還元可能性の生成(とその後の処理)
      if poss.reach2redtar?
        new_poss = poss.collect
        # 回収可能性の生成(とその後の処理)
        collectposses_then_postprocess(new_poss)
      else
        []
      end
    else
      abort 'Abort in calc_poss'
    end
  end
  
  #-----------------------------------------------------------------------------
  # collectposses_then_postprocess
  #-----------------------------------------------------------------------------
  def collectposses_then_postprocess(new_poss)
    # new_poss を可能なだけ回収し、その途上で現れる各可能性に対し計算を行う。
    collect_seq(new_poss).concatall {|p|
      if p[-1].is_Root? or p[-1].not_completed?
        [p]
      elsif p[-1].completed?
        calc_poss(p)
      end
    }
  end
  def collect_seq(poss)
    # poss を回収して得られる可能性の列を返す。
    acc = [poss]
    while true
      p = acc[-1] # abbrev: poss
      if p[-1].is_Root?
        break
      elsif p[-1].completed? and p.reach2redtar?
        acc << p.collect
      else
        break
      end
    end
    acc
  end

  #-----------------------------------------------------------------------------
  # Poss
  #-----------------------------------------------------------------------------
  class Poss < Array
    def initialize(poss)
      self << poss.shift until poss.length == 0
    end
    def root
      self[0]
    end
    def collect
      Poss.new( self[0...-2] << self[-2].collect_pterm(self[-1]) )
    end
    # ^^^ pterm :abbrev: poss's term : poss の各要素になりうる object のこと ^^^
    # いいかえると、 Root または Branch または Terminal のこと。
    # NonTerminal は pterm にはなり得ないことに注意(Branch に吸収されるため)。
    def reach2redtar?
      self[-2].redtar == self[-1].gsym
    end
    def inspect
      if self.length > 1
        self[1..-1].map{|pterm| pterm.inspect }.join(':')
      elsif self.length == 1
        self[0].inspect # Root の inspect
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Root & Branch
  #-----------------------------------------------------------------------------
  class Root
    attr_reader :collection # 解析木を見て計算するときに使う。
    def initialize(collection=[])
      # 開始記号はモジュール変数 @@start_symbol にいれておく。
      @collection = collection
    end
    def completed?
      @collection.length == 1
    end
    def not_completed?
      @collection.length == 0
    end
    def is_Root?
      true
    end
    def redtar
      @@start_symbol
    end
    def collect_pterm(pterm)
      Root.new(@collection + [pterm])
    end
    def inspect
      'Root' + @collection[0].inspect
    end
  end
  class Branch
    attr_reader :rule, :collection # 解析木を見て計算するときに使う。
    def initialize(rule, collection)
      @rule = rule
      @collection = collection # 回収した文字を格納するための Array.
    end
    def completed?
      @rule[1].length == @collection.length
    end
    def not_completed?
      @rule[1].length >  @collection.length
    end
    def is_Root?
      false
    end
    def redtar
      @rule[1][@collection.length]
    end
    def gsym # abbrev: grammar symbol 文法記号
      # completed のときにのみ呼ぶこと。 completed のときに self が表す非終端文字を返す
      @rule[0]
    end
    def collect_pterm(pterm)
      Branch.new(@rule, @collection + [pterm])
    end
    def inspect
      # '|' の手前
      collection_str = @collection.map{|pterm| pterm.inspect }.join
      # '|' の後を付け加えて body_str を作る。
      j = @collection.length
      body = @rule[1]
      body_str =
        collection_str +
        (j<body.length ? '|' + body[j..-1].map{|gsym| gsym.inspect }.join : '' )
      # 返す。
      "[#{@rule[0].inspect}=#{body_str}]"
    end
  end

  module_function :set_grammar!, :parse
end # end of module Parser




def the_completed_pterm(poss_ary)
  # poss_ary から完成した木を一つ取り出す。
  # 曖昧さのない RULESET の下で、
  # かつ poss_ary が完成した Poss (高々一つ)を含むときに使うこと。
  return poss_ary if poss_ary.is_a?(QError)
  trees = poss_ary.select{|poss|poss.root.completed?}
  if trees.length>=2
    QError.new('Parse error : ambiguous : trees : ' + trees.inspect)
  elsif trees.length==0
    QError.new('Parse error : possibilities are all incomplete.')
  else
    trees[0].root.collection[0]
  end
end







