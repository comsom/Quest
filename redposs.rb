# redposs :abbrev: reduction possibility を計算して
# file に save するためのプログラム。

# usage: ruby redposs.rb save

require 'arraymethods'

module RedPoss

  def set_ruleset!(ruleset)
    @@ruleset = ruleset
    puts('set_ruleset! : ruleset : ' + ruleset.inspect)
  end

  def make_redposs
    # res[redtar][gsym] でもって、
    # その頭部が firstnts(redtar) に含まれ、かつその本体が gsym で始まるような rule
    # をすべて集めた配列を返すような res を作るためのメソッド。
    # 1. 準備
    nonterminals = @@ruleset.map{|rule| rule[0] }.uniq          # 非終端記号全て
    gsyms = @@ruleset.concatall{|rule| [rule[0]]+rule[1] }.uniq # 文法記号全て
    puts('make_redposs : nonterminals : ' + nonterminals.inspect)
    # 2. hash の生成
    nonterminals.inject({}) {|res, redtar|
      res[redtar] = gsyms.inject({}) {|acc, gsym|
        acc[gsym] = @@ruleset.select{|rule|
          ([redtar] + firstnts(redtar)).include?(rule[0]) and rule[1][0] == gsym
        }
        acc
      }
      res
    } 
  end
  def firstnts(nonterminal) # nts :abbrev: nonterminals
    # nonterminal から生成される文法記号列の
    # 先頭に現れうる非終端文字をすべて集めた配列を返す
    firstnts_inner([], [nonterminal])
  end
  def firstnts_inner(res, news)
    # res  : 今までに得た非終端文字を貯めておくための配列。
    # news : これから試す非終端文字の queue
    #  n   : news[0] が直接生成する文法記号列の頭にある非終端記号をすべて集め、
    # vvv   その集合からすでに得ている res の記号を取り払ったもの。
    n = heads_of_dirder(news[0]).
      select{|gsym| gsym.is_nonterminal? }.setminus(res)
    next_news = news[1..-1] + n
    if next_news.any?
      firstnts_inner(res+n, next_news)
    else
      res+n
    end
  end
  def heads_of_dirder(nonterminal) # dirder :abbrev: direct derivation
    # self が直接導出する文法記号列の頭にある記号をすべて返す。
    @@ruleset.select{|rule| rule[0] == nonterminal }.map{|rule| rule[1][0] }
  end

  module_function :set_ruleset!, :make_redposs
end





if $0 == __FILE__
  # usage: ruby redposs.rb (save|print)
  MODE     = ARGV[0]
  FILENAME = 'redposs.dat' # 原則としてこれを data file に使う
  if MODE == 'save'
    include RedPoss

    require 'gquest'
    include GQuest
    set_ruleset!( RULESET )

    redposs = make_redposs
    puts('make_redposs : redposs : ' + redposs.inspect)
    f = File::open(FILENAME, 'w')
    Marshal.dump(redposs, f)
    f.close
  elsif MODE == 'print'  # 表示モード。
    require 'grammar'

    f = File::open(FILENAME, 'r')
    redposs = Marshal.load(f)
    puts('loaded redposs : ' + redposs.inspect)
  end
end

