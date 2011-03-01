# desc: 文法集。 fparser が扱える文法の例がある。

# Quest との直接の関係はない。

require 'gsym'

module GSumMul
  E   = NonTerminal.new(:e)
  T   = NonTerminal.new(:t)
  F   = NonTerminal.new(:f)
  A   = Terminal.new(:a)
  ADD = Terminal.new(:+)
  MUL = Terminal.new(:*)
  OP  = Terminal.new(:'(')
  CP  = Terminal.new(:')')
  RULESET =
    [[E, [E,ADD,T]], [E, [T]      ],    # e = e + t | t
     [T, [T,MUL,F]], [T, [F]      ],    # t = t * f | f
     [F, [A]      ], [F, [OP,E,CP]]     # f = a | ( e )
    ]
  START_SYMBOL = E
end

module GCCCA
  S   = NonTerminal.new(:s)
  T   = NonTerminal.new(:t)
  U   = NonTerminal.new(:u)
  V   = NonTerminal.new(:v)
  A   = Terminal.new(:a)
  B   = Terminal.new(:b)
  C   = Terminal.new(:c)
  RULESET =
    [[S, [U,A]  ], [S, [V,B]],   # s = u a | v b
     [T, [C,U,V]], [T, [C]  ],   # t = c u v | c
     [U, [V,T]  ], [U, [T]  ],   # u = v t | t
     [V, [U,T]  ], [V, [T]  ]    # v = u t | t
    ]
  START_SYMBOL = S
end

module GSumMul2
  # e = e + e | e * e | e | ( e )      ... 曖昧な文法の例
  E   = NonTerminal.new(:e)
  A   = Terminal.new(:a)
  ADD = Terminal.new(:+)
  MUL = Terminal.new(:*)
  OP  = Terminal.new(:'(')
  CP  = Terminal.new(:')')
  RULESET = [[E,[E,ADD,E]], [E,[E,MUL,E]], [E,[A]], [E,[OP,E,CP]]]
  START_SYMBOL = E
end

module GFunCall
  # expr  = expr ( args ) | ( expr ) | a
  # args  = args1                         ... args=ε は無い。
  # args1 = expr | args1 , expr
  EXPR  = NonTerminal.new(:expr)
  ARGS  = NonTerminal.new(:args)
  ARGS1 = NonTerminal.new(:args1)
  A      = Terminal.new(:a)
  OP     = Terminal.new(:'(')
  CP     = Terminal.new(:')')
  COMMA  = Terminal.new(:',')
  RULESET =
    [[EXPR,[EXPR,OP,ARGS,CP]], [EXPR,[OP,EXPR,CP]], [EXPR,[A]],
     [ARGS,[ARGS1]],
     [ARGS1,[EXPR]], [ARGS1,[ARGS1, COMMA, EXPR]],
    ]
  START_SYMBOL = EXPR
end

module GDigits
  # 非負正数。0から始まるものも許す。
  # digits = digits digit | digit
  # digit  = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
  DIGITS = NonTerminal.new(:digits)
  DIGIT  = NonTerminal.new(:digit)
  ZERO   = Terminal.new(:'0')
  ONE    = Terminal.new(:'1')
  TWO    = Terminal.new(:'2')
  THREE  = Terminal.new(:'3')
  FOUR   = Terminal.new(:'4')
  FIVE   = Terminal.new(:'5')
  SIX    = Terminal.new(:'6')
  SEVEN  = Terminal.new(:'7')
  EIGHT  = Terminal.new(:'8')
  NINE   = Terminal.new(:'9')
  RULESET =
    [[DIGITS,[DIGITS,DIGIT]], [DIGITS,[DIGIT]],
     [DIGIT,[ZERO]],
     [DIGIT,[ONE]],   [DIGIT,[TWO]],   [DIGIT,[THREE]],
     [DIGIT,[FOUR]],  [DIGIT,[FIVE]],  [DIGIT,[SIX]],
     [DIGIT,[SEVEN]], [DIGIT,[EIGHT]], [DIGIT,[NINE]]
    ]
  START_SYMBOL = DIGITS
end

module GSymbol
  # symbol  = alun symbol1 | alun           # 数値で始まってはならない。
  # symbol1 = aldiun symbol1 | aldiun       # symbol の1文字目以降の部分
  # alun    = alphabet | underline
  # aldiun  = alphabet | digit | underline
  # 
  # alphabet = a | b | c | d | e | f | g | h | i | j | k | l | m |
  #            n | o | p | q | r | s | t | u | v | w | x | y | z
  SYMBOL    = NonTerminal.new(:symbol)
  SYMBOL1   = NonTerminal.new(:symbol1)
  ALUN      = NonTerminal.new(:alun)    # abbrev: alphabet or underline
  ALDIUN    = NonTerminal.new(:aldiun)  # abbrev: alphabet or digit or underline
  ALPHABET  = NonTerminal.new(:alphabet)
  A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z =
    ('a'..'z').map{|al| Terminal.new(al.intern) }
  UNDERLINE = Terminal.new(:_)
  RULESET =
    [[SYMBOL,[ALUN,SYMBOL1]], [SYMBOL,[ALUN]],
     [SYMBOL1,[SYMBOL1,ALDIUN]], [SYMBOL1,[ALDIUN]],
     [ALUN,[ALPHABET]], [ALUN,[UNDERLINE]],
     [ALDIUN,[ALPHABET]], [ALDIUN,[GDigits::DIGIT]], [ALDIUN,[UNDERLINE]],
     [ALPHABET,[A]], [ALPHABET,[B]], [ALPHABET,[C]], [ALPHABET,[D]],
     [ALPHABET,[E]], [ALPHABET,[F]], [ALPHABET,[G]], [ALPHABET,[H]],
     [ALPHABET,[I]], [ALPHABET,[J]], [ALPHABET,[K]], [ALPHABET,[L]],
     [ALPHABET,[M]], [ALPHABET,[N]], [ALPHABET,[O]], [ALPHABET,[P]],
     [ALPHABET,[Q]], [ALPHABET,[R]], [ALPHABET,[S]], [ALPHABET,[T]],
     [ALPHABET,[U]], [ALPHABET,[V]], [ALPHABET,[W]], [ALPHABET,[X]],
     [ALPHABET,[Y]], [ALPHABET,[Z]]
    ] + GDigits::RULESET              # ここまでくると parse 時間も長くなってくる。
  START_SYMBOL = SYMBOL
end

module GSExpWithSpace
  # sexps = sexps space sexp | sexp
  # sexp  = atom | list
  # atom  = symbol | digits
  # list  = ( sexps ) | ( )
  SEXPS = NonTerminal.new(:sexps)
  SEXP  = NonTerminal.new(:sexp)
  ATOM  = NonTerminal.new(:atom)
  LIST  = NonTerminal.new(:list)
  OP    = Terminal.new(:'(')
  CP    = Terminal.new(:')')
  SPACE = Terminal.new(:SPACE)
  RULESET = 
    [[SEXPS,[SEXPS,SPACE,SEXP]], [SEXPS,[SEXP]],
     [SEXP,[ATOM]], [SEXP,[LIST]],
     [ATOM,[GSymbol::SYMBOL]], [ATOM,[GDigits::DIGITS]],
     [LIST,[OP,SEXPS,CP]], [LIST,[OP,CP]]
    ] + GSymbol::RULESET # + GDigits::RULESET は要らない(digits の規則が2重に入る)
  START_SYMBOL = SEXPS
end

module GSExpressions
  # sexps = sexps sexp | sexp
  # sexp  = atom | list
  # atom  = iden | spcs | integer | string
  # list  = ( sexps ) | ( )
  SEXPS   = NonTerminal.new(:sexps)
  SEXP    = NonTerminal.new(:sexp)
  ATOM    = NonTerminal.new(:atom)
  LIST    = NonTerminal.new(:list)
  IDEN    = Terminal.new(:iden) # abbrev: identifier
  SPCS   = Terminal.new(:spcs) # abbrev: special character sequence 特殊文字の列
  INTEGER = Terminal.new(:integer)
  STRING  = Terminal.new(:string)
  OP      = Terminal.new(:'(')
  CP      = Terminal.new(:')')
  RULESET = 
    [[SEXPS,[SEXPS,SEXP]], [SEXPS,[SEXP]],
     [SEXP,[ATOM]], [SEXP,[LIST]],
     [ATOM,[IDEN]], [ATOM,[SPCS]], [ATOM,[INTEGER]], [ATOM,[STRING]],
     [LIST,[OP,SEXPS,CP]], [LIST,[OP,CP]]
    ]
  START_SYMBOL = SEXPS
end

module GQuestSimple
  # [lexer] PAIRS の定義
  PAIRS = # vvv /\A\s* (<パターン>) /x の形で与えること。
    [[/\A[ \t]* (\()          /x, Proc.new{|s| Terminal.new(:'(')          }],
     [/\A[ \t]* (\))          /x, Proc.new{|s| Terminal.new(:')')          }],
     [/\A[ \t]* (\*)          /x, Proc.new{|s| Terminal.new(:'*')          }],
     [/\A[ \t]* (\/)          /x, Proc.new{|s| Terminal.new(:'/')          }],
     [/\A[ \t]* (\%)          /x, Proc.new{|s| Terminal.new(:'%')          }],
     [/\A[ \t]* (\+)          /x, Proc.new{|s| Terminal.new(:'+')          }],
     [/\A[ \t]* (\-)          /x, Proc.new{|s| Terminal.new(:'-')          }],
     [/\A[ \t]* (\=)          /x, Proc.new{|s| Terminal.new(:'=')          }],
     # vvv integer の pattern match は + の match より後で行う。
     # vvv 逆だと 1+1 が 1 +1 と解釈されエラーになる。
     # vvv でも + の後にvvvの match をしたら -10 と書けない： - 10 と解釈される。
     # vvv lexer でなく parser に仕事を任せよう。
     [/\A[ \t]* ([\+\-]? \d+) /x, Proc.new{|s|Terminal.new(:integer,s.to_i)}],
     [/\A[ \t]* ([_\w][_\w\d]*) /x,Proc.new{|s|Terminal.new(:iden,s.intern)}],
     [/\A[ \t]* ( \'[^\']*\' | \"[^\"]*\" ) /x,
      Proc.new{|s| Terminal.new(:string, s[1...-1]) }],
     [/\A[ \t]* (\,)            /x, Proc.new{|s| Terminal.new(:',') }],
  
     # vvv sep :abbrev: separator 式の区切り・仕切り
     [/\A[ \t]* (\n | ;)        /x, Proc.new{|s| Terminal.new(:sep) }],
     [/\A[ \t]* (\\\n)          /x, Proc.new{|s| :linebond          }],
     [/\A[ \t]* (\# [^\n]*)     /x, Proc.new{|s| :line_comment      }]
    ]

  # [eliminator] eliminate の定義
  ELIMS = [:linebond, :line_comment]
  def eliminate(tokenseq)
    ts = tokenseq - ELIMS
    # vvv 連続した改行を一つに減らす vvv
    ts = unify_seps([], ts)
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
  module_function :eliminate
  
  # [parser and constructor] 文法の定義と、各文法に対する action の定義。
  # - <prim_e> = iden | integer | string | ( <expr> )
  #   <post_e> = <prim_e> | <post_e> ( <argl> ) | <post_e> ( )
  #   <argl>   = <expr> | <argl> , <expr>
  #   <mul_e>  = <post_e> |
  #              <mul_e> * <post_e> | <mul_e> / <post_e> | <mul_e> % <post_e>
  #   <add_e>  = <post_e> | <mul_e> + <post_e> | <mul_e> - <post_e>
  #   <assi_e> = <add_e> | <iden> '=' <add_e>
  #   <expr>   = <assi_e>                 # 名前を変えるだけ。分かりやすいように。
  #   <exprs>  = <exprs> sep <expr> | <expr>
  # - ^^^ こうして見ると <prim_e> = ( <expr> ) の特異性が分かる。
  # - abbrevs for <*_e>s vvv
  #   prim_e : primitive      expression
  #   post_e : postfix        expression
  #   argl   : argument list
  #   mul_e  : multiplicative expression
  #   add_e  : additive       expression
  #   assi_e : assignment     expression
  PRIM_E  = NonTerminal.new(:prim_e)
  IDEN    = Terminal.new(:iden)
  INTEGER = Terminal.new(:integer)
  STRING  = Terminal.new(:string)
  OP      = Terminal.new(:'(')
  CP      = Terminal.new(:')')
  POST_E  = NonTerminal.new(:post_e)
  ARGL    = NonTerminal.new(:argl)
  COMMA   = Terminal.new(:',')
  MUL_E   = NonTerminal.new(:mul_e)
  PROD    = Terminal.new(:'*')
  DIV     = Terminal.new(:'/')
  REM     = Terminal.new(:'%')
  ADD_E   = NonTerminal.new(:add_e)
  PLUS    = Terminal.new(:'+')
  MINUS   = Terminal.new(:'-')
  ASSI_E  = NonTerminal.new(:assi_e)
  EQUAL   = Terminal.new(:'=')
  EXPR    = NonTerminal.new(:expr)
  EXPRS   = NonTerminal.new(:exprs)
  SEP     = Terminal.new(:sep)
  calc_first = Proc.new {|c| rule_action(c[0],RA_PAIRS) }
  RA_PAIRS =
    [[[PRIM_E,[IDEN]],    calc_first],
     [[PRIM_E,[INTEGER]], calc_first],
     [[PRIM_E,[STRING]],  calc_first],
     [[PRIM_E,[OP,EXPR,CP]], Proc.new {|c| rule_action(c[1],RA_PAIRS) }],
     
     [[POST_E,[PRIM_E]],  calc_first],
     [[POST_E,[POST_E,OP,ARGL,CP]], Proc.new{|c| # abbrev: collection
        # vvv ここで返る配列は関数呼び出しを表す vvv
        [rule_action(c[0],RA_PAIRS)] + rule_action(c[2],RA_PAIRS)
      }],
     [[POST_E,[POST_E,OP,CP]], Proc.new{|c|
        # vvv ここで返る配列は関数呼び出しを表す vvv
        [rule_action(c[0],RA_PAIRS)]
      }],
     
     [[ARGL,[EXPR]], Proc.new{|c|
        # vvv ここで返る配列は cdr を表す vvv
        [rule_action(c[0],RA_PAIRS)]
      }],
     [[ARGL,[ARGL,COMMA,EXPR]], Proc.new{|c|
        # vvv ここで返る配列は cdr を表す vvv
        rule_action(c[0],RA_PAIRS) + [rule_action(c[2],RA_PAIRS)]
      }],
     
     [[MUL_E,[POST_E]], calc_first],
     [[MUL_E,[MUL_E,PROD,POST_E]], Proc.new{|c|
        [:'*', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[MUL_E,[MUL_E,DIV,POST_E]], Proc.new{|c|
        [:'/', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[MUL_E,[MUL_E,REM,POST_E]], Proc.new{|c|
        [:'%', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
  
     [[ADD_E,[MUL_E]], calc_first],
     [[ADD_E,[ADD_E,PLUS,MUL_E]], Proc.new{|c|
        [:'+', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     [[ADD_E,[ADD_E,MINUS,MUL_E]], Proc.new{|c|
        [:'-', rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
  
     [[ASSI_E,[ADD_E]], calc_first],
     [[ASSI_E,[IDEN,EQUAL,ADD_E]], Proc.new{|c|
        [:def, rule_action(c[0],RA_PAIRS), rule_action(c[2],RA_PAIRS)]
      }],
     
     [[EXPR,[ASSI_E]], calc_first],

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

module GIntSum
  # [lexer] pairs の定義
  PAIRS =
    [[/\A[ \t]* ([\+\-]? \d+) /x, Proc.new{|s| Terminal.new(:int,s.to_i)   }],
     [/\A[ \t]* (\+)          /x, Proc.new{|s| Terminal.new(:'+',s.intern) }]
    ]

  # [parser and constructor]
  # <intseq> = <intseq> integer | integer
  INTSEQ  = NonTerminal.new(:intseq)
  INT = Terminal.new(:int)
  RA_PAIRS =
    [[[INTSEQ,[INTSEQ,INT]], Proc.new{|c|
       rule_action(c[0],RA_PAIRS) + rule_action(c[1],RA_PAIRS)
     }],
     [[INTSEQ,[INT]], Proc.new{|c| rule_action(c[0],RA_PAIRS) }]
    ]
  RULESET = RA_PAIRS.transpose[0]
  START_SYMBOL = INTSEQ

end



















# vvv test code vvv

if $0 == __FILE__
  if ARGV.length != 1
    abort('Give me a mode name')
  end
  mode = ARGV[0] # 'g_sum_mul' or 'g_sum_mul_2'

  require 'redposs'
  include RedPoss

  require 'fparser'
  include Parser

  case mode
  when 'g_sum_mul'
    include GSumMul

    set_ruleset!( RULESET )
    set_grammar!( RULESET, START_SYMBOL, make_redposs() )

    poss = Poss.new([Root.new, A])
    poss_ary_1 = calc_poss(poss)
    puts("calc_poss(#{poss.inspect}) : " + poss_ary_1.inspect)

    poss_ary_2a = poss_ary_1.map{|poss| Poss.new(poss + [ADD]) }
    poss_ary_2b = calc_poss_ary( poss_ary_2a )
    puts("calc_poss_ary(#{poss_ary_2a.inspect}) : " + poss_ary_2b.inspect)

    poss_ary_3a = poss_ary_2b.map{|poss| Poss.new(poss + [A]) }
    poss_ary_3b = calc_poss_ary( poss_ary_3a )
    puts("calc_poss_ary(#{poss_ary_3a.inspect}) : " + poss_ary_3b.inspect)

  when 'g_sum_mul_2'
    include GSumMul2

    set_ruleset!( RULESET )
    set_grammar!( RULESET, START_SYMBOL, make_redposs() )

    poss_ary = parse( [A,ADD,A,MUL,A] )
    completed_poss_ary = poss_ary.select{|poss| poss.root.completed? }
    puts('a+a*a : ' + completed_poss_ary.inspect)

  else
    abort('undefined mode : ' + mode)
  end
end

