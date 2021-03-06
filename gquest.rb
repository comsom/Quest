# desc: Quest の文法

require File.expand_path('../gsym', __FILE__) # 'gsym'

module GQuest
  #-----------------------------------------------------------------------------
  # [lexer] PAIRS の定義
  #-----------------------------------------------------------------------------
  PAIRS = # vvv /\A\s* (<パターン>) /x の形で与えること。
    [# [括弧の match]
     [/\A[ \t]*  (\()      /x, Proc.new{|s| Terminal.new(:'(')   }],
     [/\A[ \t]*  (\))      /x, Proc.new{|s| Terminal.new(:')')   }],
     [/\A[ \t]*  (\[)      /x, Proc.new{|s| Terminal.new(:'[')   }],
     [/\A[ \t]*  (\])      /x, Proc.new{|s| Terminal.new(:']')   }],
     # [関係演算子・等値演算子の match]                        
     [/\A[ \t]*  (\=\=)    /x, Proc.new{|s| Terminal.new(:'==')  }],
     [/\A[ \t]*  (\!\=)    /x, Proc.new{|s| Terminal.new(:'!=')  }],
     [/\A[ \t]*  (\<\=)    /x, Proc.new{|s| Terminal.new(:'<=')  }],
     [/\A[ \t]*  (\>\=)    /x, Proc.new{|s| Terminal.new(:'>=')  }],
     [/\A[ \t]*  (\<)      /x, Proc.new{|s| Terminal.new(:'<')   }],
     [/\A[ \t]*  (\>)      /x, Proc.new{|s| Terminal.new(:'>')   }],
     # [2項演算子の match]                                      
     [/\A[ \t]*  (\+\+)    /x, Proc.new{|s| Terminal.new(:'++')  }],
     [/\A[ \t]*  (\*)      /x, Proc.new{|s| Terminal.new(:'*')   }],
     [/\A[ \t]*  (\/)      /x, Proc.new{|s| Terminal.new(:'/')   }],
     [/\A[ \t]*  (\%)      /x, Proc.new{|s| Terminal.new(:'%')   }],
     [/\A[ \t]*  (\+)      /x, Proc.new{|s| Terminal.new(:'+')   }],
     [/\A[ \t]*  (\-)      /x, Proc.new{|s| Terminal.new(:'-')   }],
     [/\A[ \t]*  (\=)      /x, Proc.new{|s| Terminal.new(:'=')   }],
     [/\A[ \t]*  (\.\.\.)  /x, Proc.new{|s| Terminal.new(:'...') }],
     [/\A[ \t]*  (\.\.)    /x, Proc.new{|s| Terminal.new(:'..')  }],
     [/\A[ \t]*  (\.)      /x, Proc.new{|s| Terminal.new(:'.')   }],
     [/\A[ \t]*  (\:)      /x, Proc.new{|s| Terminal.new(:':')   }],
     # [comma の match]    
     [/\A[ \t]*  (\,)      /x, Proc.new{|s| Terminal.new(:',') }],

     # [数値の match] ... 単項 +,- は fparser の仕事。
     [/\A[ \t]*  (\d+\.\d+) /x, Proc.new{|s|Terminal.new(:real,  s.to_f)}],
     [/\A[ \t]*  (\d+)      /x, Proc.new{|s|Terminal.new(:integer,s.to_i)}],

     # [予約語の match]    ... 識別子 match の前に行う。
     # '\b' だと不完全： if? という変数名が作れない ... うまい回避方法が見つからん。
     [/\A[ \t]*     (if\b)   /x, Proc.new{|s| Terminal.new(:if)    }],
     [/\A[ \t]*   (then\b)   /x, Proc.new{|s| Terminal.new(:then)  }],
     [/\A[ \t]*  (elsif\b)   /x, Proc.new{|s| Terminal.new(:elsif) }],
     [/\A[ \t]*   (else\b)   /x, Proc.new{|s| Terminal.new(:else)  }],
     [/\A[ \t]*    (end\b)   /x, Proc.new{|s| Terminal.new(:end)   }],
     [/\A[ \t]*    (fun\b)   /x, Proc.new{|s| Terminal.new(:fun)   }],
     [/\A[ \t]*   (true\b)   /x, Proc.new{|s| Terminal.new(:true)  }],
     [/\A[ \t]*  (false\b)   /x, Proc.new{|s| Terminal.new(:false) }],
     [/\A[ \t]*  (space\b)   /x, Proc.new{|s| Terminal.new(:space) }],
     [/\A[ \t]*   (init\b)   /x, Proc.new{|s| Terminal.new(:init)  }],
     [/\A[ \t]*    (nil\b)   /x, Proc.new{|s| Terminal.new(:nil)   }],
     [/\A[ \t]*    (and\b)   /x, Proc.new{|s| Terminal.new(:and)   }],
     [/\A[ \t]*     (or\b)   /x, Proc.new{|s| Terminal.new(:or)    }],
     [/\A[ \t]*    (not\b)   /x, Proc.new{|s| Terminal.new(:not)   }],
     [/\A[ \t]*     (on\b)   /x, Proc.new{|s| Terminal.new(:on)    }],
     [/\A[ \t]*     (do\b)   /x, Proc.new{|s| Terminal.new(:do)    }],

     # [識別子の match] iden :abbrev: identifier
     [/\A[ \t]*  ([_a-zA-Z]\w*[\?\!]*)  /x,
      Proc.new{|s| Terminal.new(:iden, s.intern) }],
     [/\A[ \t]*  ( \@s | \@p | \@r )  /x,
      Proc.new{|s| Terminal.new(:iden, s.intern) }],
     # [文字列の match]
     [/\A[ \t]*  (\'[^\']*\')  /x,
      Proc.new{|s| Terminal.new(:string, s[1...-1]) }],
     [/\A[ \t]*  (\"[^\"]*\")  /x,
      Proc.new{|s| Terminal.new(:string, s[1...-1].gsub(/\\n/,"\n")) }],

     # [区切り(仕切り)の match] sep :abbrev: separator
     [/\A[ \t]*  (\n | ;)     /x, Proc.new{|s| Terminal.new(:sep) }],
     # [行結合と行 comment の match]
     [/\A[ \t]*  (\\\n)       /x, Proc.new{|s| :linebond          }],
     [/\A[ \t]*  (\# [^\n]*)  /x, Proc.new{|s| :line_comment      }],
    ]

  # Terminal の定義
  OP      = Terminal.new(:'(') # abbrev: opening parenthesis
  CP      = Terminal.new(:')') # abbrev: closing parenthesis
  OB      = Terminal.new(:'[') # abbrev: opening bracket
  CB      = Terminal.new(:']') # abbrev: closing bracket

  EQUAL   = Terminal.new(:'==')
  NEQUAL  = Terminal.new(:'!=')
  LE      = Terminal.new(:'<=')
  GE      = Terminal.new(:'>=')
  LT      = Terminal.new(:'<')
  GT      = Terminal.new(:'>')

  CONCAT  = Terminal.new(:'++')
  PROD    = Terminal.new(:'*')
  DIV     = Terminal.new(:'/')
  REM     = Terminal.new(:'%')
  PLUS    = Terminal.new(:'+')
  MINUS   = Terminal.new(:'-')
  SUBST   = Terminal.new(:'=')
  DDDOT   = Terminal.new(:'...')
  DDOT    = Terminal.new(:'..')
  DOT     = Terminal.new(:'.')
  COLON   = Terminal.new(:':')

  COMMA   = Terminal.new(:',')

  REAL    = Terminal.new(:real)
  INTEGER = Terminal.new(:integer)

  IF      = Terminal.new(:if)
  THEN    = Terminal.new(:then)
  ELSE    = Terminal.new(:else)
  ELSIF   = Terminal.new(:elsif)
  QEND    = Terminal.new(:end)    # 定数名に END が使われていたため。名前だけQ付ける。
  FUN     = Terminal.new(:fun)
  QTRUE   = Terminal.new(:true)  # QEND に同じ。
  QFALSE  = Terminal.new(:false) # QEND に同じ。
  SPACE   = Terminal.new(:space)
  INIT    = Terminal.new(:init)
  QNIL    = Terminal.new(:nil)   # QEND に同じ。
  AND     = Terminal.new(:and)
  OR      = Terminal.new(:or)
  NOT     = Terminal.new(:not)
  ON      = Terminal.new(:on)
  DO      = Terminal.new(:do)

  IDEN    = Terminal.new(:iden)
  STRING  = Terminal.new(:string)

  SEP     = Terminal.new(:sep)

  #-----------------------------------------------------------------------------
  # [eliminator] eliminate の定義
  #-----------------------------------------------------------------------------
  ELIMS = [:linebond, :line_comment]
  def eliminate(tokenseq)
    ts = tokenseq - ELIMS
    # vvv 連続した SEP を一つに減らす vvv
    ts = unify_seps([], ts)
    # vvv tokenseq の先頭と末尾にある SEP を取り除く vvv
    ts, _ = ts.elim_sep_at(0)
    ts, _ = ts.elim_sep_at(ts.length-1)
    # vvv if, space の直後にある SEP, then, else, init の前後にある SEP,
    # vvv end の直前にある SEP , をすべて消す。
    ts = elim_adjoining_seps(ts, 0)
    # vvv fun の後にある SEP を消す。
    ts = elim_fun_seps(ts, 0)
  end

  def unify_seps(acc, tokenseq)
    # tokenseq 内で連続している複数の sep を一つに直した配列を返す。
    # 例： unify_seps([a,sep,b,sep,sep,c,sep]) #=> [a,sep,b,sep,c,sep]
    if tokenseq.empty?
      acc
    elsif tokenseq[0] != SEP # SEP は [parser] で定義している。
      unify_seps( acc << tokenseq[0], tokenseq[1..-1] )
    else
      unify_seps( acc << tokenseq[0], skip_seps(tokenseq[1..-1]) )
    end
  end
  def skip_seps(tokenseq)
    # 先頭にある sep をすべて除いた配列を返す。
    # 例： skip_seps([sep,sep,p,q,r]) #=> [p,q,r]
    if tokenseq.empty? or tokenseq[0] != SEP
      tokenseq
    else
      skip_seps(tokenseq[1..-1])
    end
  end

  def elim_adjoining_seps(tokenseq, i)
    # tokenseq の index i を増やしながら tokenseq を捜査していく。
    if i == tokenseq.length
      tokenseq
    elsif [IF,SPACE,ON].include?(tokenseq[i])  # [OP,OB,IF,SPACE]
      # 直後に来る sep を取り除く。
      t, _ = tokenseq.elim_sep_at(i+1)     # _ は使わない。
      elim_adjoining_seps(t, i+1)
    elsif [THEN,ELSIF,ELSE,INIT,DO].include?(tokenseq[i])
      # 前後に来る sep を取り除く。
      t, _ = tokenseq.elim_sep_at(i+1)
      # puts('debugwrite : [t,i] : ' + [t,i].inspect)
      t, n = t.elim_sep_at(i-1)
      elim_adjoining_seps(t, i+1-n)
    elsif [QEND].include?(tokenseq[i])   # [CP,CB,QEND]
      # 直前に来る sep を取り除く。
      t, n = tokenseq.elim_sep_at(i-1)
      elim_adjoining_seps(t, i+1-n)
    else
      elim_adjoining_seps(tokenseq, i+1)
    end
  end

  def elim_fun_seps(tokenseq, i)
    if i == tokenseq.length
      tokenseq
    elsif tokenseq[i] == FUN
      # tokenseq[i..-1] で最初に現れる閉じ括弧の直後にある SEP を除去する。
      k = tokenseq[i..-1].index(CP)
      t, _ = tokenseq.elim_sep_at(i+k+1)
      elim_fun_seps(t, i+k+1)
    else
      elim_fun_seps(tokenseq, i+1)
    end
  end

  module_function :eliminate
  
  #-----------------------------------------------------------------------------
  # [parser and constructor] 文法の定義と、各文法に対する action の定義。
  #-----------------------------------------------------------------------------
  # - <prim_e>  = iden | real | integer | string | true | false | nil
  #             | ( <expr> ) | [ <argl> ] | [ ]
  #   <argl>    = <expr> | <argl> , <expr>
  #   <post_e>  = <prim_e>
  #             | <post_e> ( <argl> ) | <post_e> ( )
  #             | <post_e> [ <expr> ]
  #             | <post_e> . <iden>
  #             | <post_e> : <iden>
  #   <unary_e> = <post_e> | + <unary_e> | - <unary_e>
  #   <mul_e>   = <unary_e> | <mul_e> % <unary_e>
  #             | <mul_e> * <unary_e> | <mul_e> / <unary_e>
  #   <add_e>   = <mul_e> | <add_e> + <mul_e> | <add_e> - <mul_e>
  #             | <add_e> ++ <mul_e>
  #   <rel_e>   = <add_e>
  #             | <rel_e> '<=' <add_e> | <rel_e> '>=' <add_e>
  #             | <rel_e> '<'  <add_e> | <rel_e> '>'  <add_e>
  #   <eq_e>    = <rel_e> | <eq_e> '==' <add_e> | <eq_e> '!=' <add_e>
  #   <range_e> = <eq_e> | <range_e> ... <eq_e> | <range_e> .. <eq_e>
  #   <if_e>    = <range_e>
  #             | if <expr> then <exprs>                        end
  #             | if <expr> then <exprs>           else <exprs> end
  #             | if <expr> then <exprs> <elsif_c>              end
  #             | if <expr> then <exprs> <elsif_c> else <exprs> end
  #   <elsif_c> =           elsif <expr> then <exprs>
  #             | <elsif_c> elsif <expr> then <exprs>
  #   <fun_e>   = <if_e>
  #             | fun iden ( <params> ) <exprs> end
  #             | fun iden (          ) <exprs> end
  #             | fun      ( <params> ) <exprs> end
  #             | fun      (          ) <exprs> end
  #   <params>  = iden | <params> , iden
  #   <sp_e>    = <fun_e>
  #             | space end
  #             | space <exprs> end
  #             | space <iden> init <exprs> end
  #   <on_do_e> = <sp_e> | on <expr> do <exprs> end
  #   <assi_e>  = <on_do_e> | <left_e> '=' <on_do_e>
  #   <left_e>  = <iden> | <post_e> : <iden>
  #   <not_e>   = <assi_e> | not <not_e>
  #   <and_e>   = <not_e> | <and_e> and <not_e>
  #   <or_e>    = <and_e> | <or_e>  or  <or_e>
  #   <expr>    = <or_e>                 # 名前を変えるだけ。分かりやすいように。
  #   <exprs>   = <exprs> sep <expr> | <expr>
  # - ^^^ こうして見ると <prim_e> = ( <expr> ) の特異性が分かる。
  # - abbrevs for <*_e>s vvv
  #   prim_e : primitive      expression
  #   post_e : postfix        expression
  #   argl   : argument list
  #   mul_e  : multiplicative expression
  #   add_e  : additive       expression
  #   assi_e : assignment     expression
  PRIM_E  = NonTerminal.new(:prim_e)
  ARGL    = NonTerminal.new(:argl)
  POST_E  = NonTerminal.new(:post_e)
  UNARY_E = NonTerminal.new(:unary_e)
  MUL_E   = NonTerminal.new(:mul_e)
  ADD_E   = NonTerminal.new(:add_e)
  REL_E   = NonTerminal.new(:rel_e)
  EQ_E    = NonTerminal.new(:eq_e)
  RANGE_E = NonTerminal.new(:range_e)
  IF_E    = NonTerminal.new(:if_e)
  ELSIF_C = NonTerminal.new(:elsif_c)
  FUN_E   = NonTerminal.new(:fun_e)
  PARAMS  = NonTerminal.new(:params)
  SP_E    = NonTerminal.new(:sp_e)
  ON_DO_E = NonTerminal.new(:on_do_e)
  ASSI_E  = NonTerminal.new(:assi_e)
  LEFT_E  = NonTerminal.new(:left_e)
  NOT_E   = NonTerminal.new(:not_e)
  AND_E   = NonTerminal.new(:and_e)
  OR_E    = NonTerminal.new(:or_e)
  EXPR    = NonTerminal.new(:expr)
  EXPRS   = NonTerminal.new(:exprs)
  calc_first = Proc.new {|c| rule_action(c[0],RA_PAIRS) }
  RA_PAIRS =
    [[[PRIM_E,[IDEN]],    calc_first],
     [[PRIM_E,[INTEGER]], calc_first],
     [[PRIM_E,[REAL]],    calc_first],
     [[PRIM_E,[STRING]],  calc_first],
     [[PRIM_E,[QTRUE]],   Proc.new{|c| true  }],
     [[PRIM_E,[QFALSE]],  Proc.new{|c| false }],
     [[PRIM_E,[QNIL]],    Proc.new{|c| nil   }],
     [[PRIM_E,[OP,EXPR,CP]], Proc.new {|c| rule_action(c[1],RA_PAIRS) }],
     [[PRIM_E,[OB,ARGL,CB]],
      Proc.new {|c| [:'[new]'] + rule_action(c[1],RA_PAIRS) }],
     [[PRIM_E,[OB,CB]],
      Proc.new {|c| [:'[new]'] }],
     
     [[ARGL,[EXPR]], Proc.new{|c|
        # vvv ここで返る配列は cdr を表す vvv
        [rule_action(c[0],RA_PAIRS)]
      }],
     [[ARGL,[ARGL,COMMA,EXPR]], Proc.new{|c|
        # vvv ここで返る配列は cdr を表す vvv
        rule_action(c[0],RA_PAIRS) + [rule_action(c[2],RA_PAIRS)]
      }],
     
     [[POST_E,[PRIM_E]],  calc_first],
     [[POST_E,[POST_E,OP,ARGL,CP]], Proc.new{|c| # abbrev: collection
        # vvv ここで返る配列は関数呼び出しを表す vvv
        pe = rule_action(c[0],RA_PAIRS)
        if (not pe.is_a?(Array)) or (pe[0] != :'.')    #==> 普通の関数呼び出し
          [pe] + rule_action(c[2],RA_PAIRS)
        else # i.e. pe[0] != :'.'                     ==> dot呼び出し
          pe + rule_action(c[2],RA_PAIRS)
        end
      }],
     [[POST_E,[POST_E,OP,CP]], Proc.new{|c|
        # vvv ここで返る配列は関数呼び出しを表す vvv
        pe = rule_action(c[0],RA_PAIRS)
        if (not pe.is_a?(Array)) or pe[0] != :'.'      #==> 普通の関数呼び出し
          [pe]
        else # i.e. pe[0] != :'.'   ==> dot呼び出し
          pe
        end
      }],
     [[POST_E,[POST_E,OB,EXPR,CB]], Proc.new{|c|
        [:'[ref]', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[POST_E,[POST_E,DOT,IDEN]], Proc.new{|c|
        [:'.', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[POST_E,[POST_E,COLON,IDEN]], Proc.new{|c|
        [:':', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     
     [[UNARY_E,[POST_E]], calc_first],
     [[UNARY_E,[PLUS,UNARY_E]], Proc.new{|c|
        [:'u+', rule_action(c[1],RA_PAIRS)]
      }],
     [[UNARY_E,[MINUS,UNARY_E]], Proc.new{|c|
        [:'u-', rule_action(c[1],RA_PAIRS)]
      }],

     [[MUL_E,[UNARY_E]], calc_first],
     [[MUL_E,[MUL_E,REM,UNARY_E]], Proc.new{|c|
        [:'%', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[MUL_E,[MUL_E,PROD,UNARY_E]], Proc.new{|c|
        [:'*', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[MUL_E,[MUL_E,DIV,UNARY_E]], Proc.new{|c|
        [:'/', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
  
     [[ADD_E,[MUL_E]], calc_first],
     [[ADD_E,[ADD_E,PLUS,MUL_E]], Proc.new{|c|
        [:'+', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[ADD_E,[ADD_E,MINUS,MUL_E]], Proc.new{|c|
        [:'-', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[ADD_E,[ADD_E,CONCAT,MUL_E]], Proc.new{|c|
        [:'++', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
  
     [[REL_E,[ADD_E]], calc_first],
     [[REL_E,[REL_E,LE,ADD_E]], Proc.new{|c|
        [:'<=', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[REL_E,[REL_E,GE,ADD_E]], Proc.new{|c|
        [:'>=', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[REL_E,[REL_E,LT,ADD_E]], Proc.new{|c|
        [:'<', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[REL_E,[REL_E,GT,ADD_E]], Proc.new{|c|
        [:'>', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[EQ_E,[REL_E]], calc_first],
     [[EQ_E,[EQ_E,EQUAL,REL_E]], Proc.new{|c|
        [:'==', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[EQ_E,[EQ_E,NEQUAL,REL_E]], Proc.new{|c|
        [:'!=', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[RANGE_E,[EQ_E]], calc_first],
     [[RANGE_E,[RANGE_E,DDDOT,EQ_E]], Proc.new{|c|
        [:'...', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[RANGE_E,[RANGE_E,DDOT,EQ_E]], Proc.new{|c|
        [:'..',  rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[IF_E,[RANGE_E]], calc_first],
     [[IF_E,[IF,EXPR,THEN,EXPRS,QEND]], Proc.new{|c|
        [:if, [rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)]
      }],
     [[IF_E,[IF,EXPR,THEN,EXPRS,ELSE,EXPRS,QEND]], Proc.new{|c|
        [:if, [rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)] +
        [[:else] + rule_action(c[5],RA_PAIRS)]
      }],
     [[IF_E,[IF,EXPR,THEN,EXPRS,ELSIF_C,QEND]], Proc.new{|c|
        [:if, [rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)] +
        rule_action(c[4],RA_PAIRS)
      }],
     [[IF_E,[IF,EXPR,THEN,EXPRS,ELSIF_C,ELSE,EXPRS,QEND]], Proc.new{|c|
        [:if, [rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)] +
        rule_action(c[4],RA_PAIRS) +
        [[:else] + rule_action(c[6],RA_PAIRS)]
      }],
     
     [[ELSIF_C,[ELSIF,EXPR,THEN,EXPRS]], Proc.new{|c|
        [[rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)]
      }],
     [[ELSIF_C,[ELSIF_C,ELSIF,EXPR,THEN,EXPRS]], Proc.new{|c|
        rule_action(c[0],RA_PAIRS) +
        [[rule_action(c[2],RA_PAIRS)] + rule_action(c[4],RA_PAIRS)]
      }],

     [[FUN_E,[IF_E]], calc_first],
     [[FUN_E,[FUN,IDEN,OP,PARAMS,CP,EXPRS,QEND]], Proc.new{|c|
        [:'=', rule_action(c[1],RA_PAIRS),
         [:fun, rule_action(c[3],RA_PAIRS), rule_action(c[5],RA_PAIRS)]
        ]
      }],
     [[FUN_E,[FUN,IDEN,OP,CP,EXPRS,QEND]], Proc.new{|c|
        [:'=', rule_action(c[1],RA_PAIRS),
          [:fun, [], rule_action(c[4],RA_PAIRS)]
        ]
      }],
     [[FUN_E,[FUN,OP,PARAMS,CP,EXPRS,QEND]], Proc.new{|c|
        [:fun, rule_action(c[2],RA_PAIRS), rule_action(c[4],RA_PAIRS)]
      }],
     [[FUN_E,[FUN,OP,CP,EXPRS,QEND]], Proc.new{|c|
        [:fun, [], rule_action(c[3],RA_PAIRS)]
      }],

     [[PARAMS,[IDEN]], Proc.new{|c|
        [rule_action(c[0],RA_PAIRS)]
      }],
     [[PARAMS,[PARAMS,COMMA,IDEN]], Proc.new{|c|
        rule_action(c[0],RA_PAIRS) + [rule_action(c[2],RA_PAIRS)]
      }],

     [[SP_E,[FUN_E]], calc_first],
     [[SP_E,[SPACE,QEND]], Proc.new{|c|
        [:space, []]
      }],
     [[SP_E,[SPACE,EXPRS,QEND]], Proc.new{|c|
        [:space, rule_action(c[1],RA_PAIRS)]
      }],
     [[SP_E,[SPACE,IDEN,INIT,EXPRS,QEND]], Proc.new{|c|
        [:'=', rule_action(c[1],RA_PAIRS),
          [:space, rule_action(c[3],RA_PAIRS)]
        ]
      }],

     [[ON_DO_E,[SP_E]], calc_first],
     [[ON_DO_E,[ON,EXPR,DO,EXPRS,QEND]], Proc.new{|c|
        [:'on_do', rule_action(c[1],RA_PAIRS)] + rule_action(c[3],RA_PAIRS)
      }],

     [[ASSI_E,[ON_DO_E]], calc_first],
     [[ASSI_E,[LEFT_E,SUBST,ON_DO_E]], Proc.new{|c|
        [:'=', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[LEFT_E,[IDEN]], calc_first],
     [[LEFT_E,[POST_E,COLON,IDEN]], Proc.new{|c|
        [:':', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[NOT_E,[ASSI_E]], calc_first],
     [[NOT_E,[NOT,NOT_E]], Proc.new{|c|
        [:not, rule_action(c[1],RA_PAIRS)]
      }],

     [[AND_E,[NOT_E]], calc_first],
     [[AND_E,[AND_E,AND,NOT_E]], Proc.new{|c|
        [:and, rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[OR_E,[AND_E]], calc_first],
     [[OR_E,[OR_E,OR,AND_E]], Proc.new{|c|
        [:or, rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],

     [[EXPR,[OR_E]], calc_first],

     [[EXPRS,[EXPR]], Proc.new{|c|
        # vvv ここで返る配列は式の列を表す vvv
        [rule_action(c[0],RA_PAIRS)]
      }],
     [[EXPRS,[EXPRS,SEP,EXPR]], Proc.new {|c|
        # vvv ここで返る配列は式の列を表す vvv
        rule_action(c[0],RA_PAIRS) + [rule_action(c[2],RA_PAIRS)]
      }],
    ]
  RULESET = RA_PAIRS.transpose[0]
  START_SYMBOL = EXPRS
end

class Array
  def elim_sep_at(j)
    # index j に SEP があれば、それを self から除去した配列を返す。
    # 除去した数も返す。これは1(除去した)か0(除去しなかった)のいずれかとなる。
    t = self
    n = 0
    if self[j] == SEP
      t = self[0...j] + self[(j+1)..-1]
      n = 1
    end
    [t,n]
  end
end















if $0 == __FILE__
  # date: 8;2011/2/20 (sun)

  # space, dot(.) の tokenize, eliminate の check.
  
  include GQuest

  #----------------------------------------------------
  puts;puts('Quest : tokenize and eliminate the code.')
  
  require 'lexer'

  # code = "x=15; \n space x=1000.to_s \n sq=x*x end"
  code = "x=15.quot_power(3,5); \n Integer:a=x*x \n x=1000.to_s"
  puts('code : ' + code.inspect)
  tokenseq = match_action(code, PAIRS)
  puts('match_action #=> ' + tokenseq.inspect)
  tokenseq = eliminate( tokenseq )
  puts('eliminate #=>' + tokenseq.inspect)

  #exit
  
  #-----------------------------------------------------
  puts;puts('Quest : parse and construct the tokenseq.')
  
  require 'fparser'
  include Parser
  require 'constructor'

  f = File::open('redposs.dat', 'r')
  redposs = Marshal.load(f)
  f.close
  set_grammar!( RULESET, START_SYMBOL, redposs )

  pterm = the_completed_pterm( parse( tokenseq ) )
  puts('parse #=> ' + pterm.inspect)
  sexps = rule_action(pterm, RA_PAIRS)
  puts('rule_action #=> ' + sexps.inspect)
end


if $0 == __FILE__
  #-----------------------------------------------------
  puts;puts('Quest : run the code.')
  
  include GQuest

  require 'lexer'

  require 'fparser'
  include Parser
  require 'constructor'

  f = File::open('redposs.dat', 'r')
  redposs = Marshal.load(f)
  f.close
  set_grammar!( RULESET, START_SYMBOL, redposs )

  require 'evaluator'
  
  def put_code_eval(code)
    puts;puts('code : ' + code.inspect)

    tokenseq = match_action(code, PAIRS)
    # puts('match_action #=> ' + tokenseq.inspect)

    tokenseq = eliminate(tokenseq)
    # puts('eliminate #=> ' + tokenseq.inspect)

    pterm = the_completed_pterm( parse( tokenseq ) )
    sexps = rule_action(pterm, RA_PAIRS)
    sexps.each{|sexp|
      puts(sexp.inspect)
      puts('s_eval #=> ' + s_eval(sexp,SP_TOPLEVEL).inspect)
    }
  end

  code = "fun gcd(a,b) r = a%b; if r==0 then b else gcd(b,r) end end
          gcd(2*5, 3*5)"
  put_code_eval(code)
  code = ' (111*111).to_s() '
  put_code_eval(code)
  code = 'Integer:sq = (fun _() @r*@r end); 15.sq' # 15.sq() も試すべし
  put_code_eval(code)
  code = "space S init x=5; fun x2s() x.to_s end end
          S.x2s
          S:x = 77
          S.x2s "
  put_code_eval(code)

  exit
end









if $0 == __FILE__
  # date: 7;2011/2/15 (tue)

  # require 'lexer'
  # 
  # include GQuest
  # 
  # #----------------------------------------------------
  # puts;puts('Quest : tokenize and eliminate the code.')
  # 
  # code = "x=15; p=4 \n if 1000 ; then \n x*x \n else p end"
  # puts('code : ' + code.inspect)
  # tokenseq = match_action(code, PAIRS)
  # puts('match_action #=> ' + tokenseq.inspect)
  # tokenseq = eliminate( tokenseq )
  # puts('eliminate #=>' + tokenseq.inspect)
  # 
  # #-----------------------------------------------------
  # puts;puts('Quest : parse and construct the tokenseq.')
  # 
  # require 'fparser'
  # include Parser
  # set_grammar!( RULESET, START_SYMBOL )
  # require 'constructor'
  # 
  # pterm = the_completed_pterm( parse( tokenseq ) )
  # puts('parse #=> ' + pterm.inspect)
  # sexps = rule_action(pterm, RA_PAIRS)
  # puts('rule_action #=> ' + sexps.inspect)
  # 
  # #----------------------------------------------------------
  # puts;puts('Quest : evaluate the constructed s-expression.')
  # 
  # def put_seq_eval(sexps)
  #   puts
  #   sexps.each{|sexp|
  #     puts(sexp.inspect)
  #     puts('s_eval #=> ' + s_eval(sexp,BASE_NAMESPACE).inspect)
  #   }
  # end
  # 
  # require 'evaluator'
  # 
  # put_seq_eval(sexps)



  # #-----------------------------------------------
  # puts;puts('-' * 80)
  # puts('Quest : tokenize and eliminate the code.')
  # 
  # code = " fun sq_sum(x,y) \n\n\n x*x + y*y end; sq_sum(12,5) "
  # puts('code : ' + code.inspect)
  # tokenseq = match_action(code, PAIRS)
  # puts('match_action #=> ' + tokenseq.inspect)
  # tokenseq = eliminate( tokenseq )
  # puts('eliminate #=>' + tokenseq.inspect)
  # 
  # #-----------------------------------------------------
  # puts;puts('Quest : parse and construct the tokenseq.')
  # 
  # require 'fparser'
  # include Parser
  # set_grammar!( RULESET, START_SYMBOL )
  # require 'constructor'
  # 
  # pterm = the_completed_pterm( parse( tokenseq ) )
  # puts('parse #=> ' + pterm.inspect)
  # sexps = rule_action(pterm, RA_PAIRS)
  # puts('rule_action #=> ' + sexps.inspect)
  # 
  # #----------------------------------------------------------
  # puts;puts('Quest : evaluate the constructed s-expression.')
  # 
  # def put_seq_eval(sexps)
  #   puts
  #   sexps.each{|sexp|
  #     puts(sexp.inspect)
  #     puts('s_eval #=> ' + s_eval(sexp,BASE_NAMESPACE).inspect)
  #   }
  # end
  # 
  # require 'evaluator'
  # 
  # put_seq_eval(sexps)



  include GQuest
  require 'lexer'
  require 'fparser'
  include Parser

  f = File::open('redposs.dat', 'r')
  redposs = Marshal.load(f)
  f.close
  set_grammar!( RULESET, START_SYMBOL, redposs )

  require 'constructor'
  require 'evaluator'
  
  def put_seq_eval(sexps)
    puts
    sexps.each{|sexp|
      puts(sexp.inspect)
      puts('s_eval #=> ' + s_eval(sexp,BASE_NAMESPACE).inspect)
    }
  end


#   code = <<CODE
#     if false
#     then puts("I won't be puts.")
#     else puts("I'll be puts.")
#     end
# CODE
  code = "fun gcd(a,b) r = a%b; if r==0 then b else gcd(b,r) end end
          gcd(2*5, 3*5)"
  # 関数リテラル
  code = "(fun sq(x) x*x end)(7)"
  # 繰り返し
  code = "fun iter(i,n,f) if i<n then f(i);iter(i+1,n,f) end end
          # iter(0,5, fun(x) puts('hello' ++ to_s(x)) end)
          iter(0,5, fun _(x) puts('hello') end)"
  # adder ... 値が蓄積しない : def の意味だと、_ の関数呼び出し内で定義されてしまう。
  code = "fun adder!?(n) fun _(i) n=n+i end end
          a = adder!?(3)
          a(5)
          a(0-12)"

  #tokenseq = eliminate(match_action(code,PAIRS))
  tokenseq = match_action(code, PAIRS)
  puts('match_action #=> ' + tokenseq.inspect)
  tokenseq = eliminate(tokenseq)
  puts('eliminate #=> ' + tokenseq.inspect)
  #exit
  pterm = the_completed_pterm( parse( tokenseq ) )
  sexps = rule_action(pterm, RA_PAIRS)
  put_seq_eval(sexps)

end
