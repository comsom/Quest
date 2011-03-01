# desc: lexer 字句解析器

# vvv lexer method vvv
def match_action(string, pairs) # abbrev: Pattern-Action PAirs
  # 複数の pattern-action を扱う。
  # いずれかの pattern に match したら、対応する action を実行する。
  match_action_inner([], string, pairs)
end
def match_action_inner(acc, string, pairs)
  val, rest = get_token(string, pairs)
  if val != nil
    # puts("debugwrite : val, rest : #{val.inspect}, #{rest.inspect}")
    match_action_inner( acc << val, rest, pairs )
  else
    # puts('debugwrite in mainner : ' + rest.inspect)
    acc
  end
end
def get_token(string, pairs)
  # string が pairs 内にあるいずれかの pattern に match した場合、
  # 対応する action を $& にかけたものと残りの文字列 $' 返す。
  # さもなくば nil を返す。
  pairs.each{|pattern, action|
    if string =~ pattern
      return [action.call($1), $']
    end
  }
  nil
end















if $0 == __FILE__
  pairs =
    [[/\A[ \t]*  ([_a-zA-Z]+)  /x, Proc.new{|s| puts('word : ' + s);s }],
     [/\A[ \t]*  (\d+)         /x, Proc.new{|s| puts('digits : ' + s);s }],
    ]
  s = ' single 777 simple 333 sample '

  puts(s)
  puts('match_action #=> ' + match_action(s, pairs).inspect)
end

