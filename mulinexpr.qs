# desc: 複数行にまたがる式     mulinexpr :abbrev: multi-line expression

# Quest の式の区切りは改行と semi-colon(;) の2種あります。
# 1行に複数の式を書きたいときは semi-colon(;) を用いれば良いのですが、
# 複数行に1つの式を書きたいときは以下のように行末に backslash(\) を置きます。

a = 1 + 3 \
* 4

# こうすることで backslash(\) の直後にくる改行を無視することができます。

puts(a.to_s)

