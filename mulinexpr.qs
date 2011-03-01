# desc: 複数行にまたがる式の例     mulinexpr :abbrev: multi-line expression

# Quest の式の区切りに改行と semi-colon(;) の2種を用います。
# 1行に複数の式を書きたいときは semi-colon(;) を用いれば良いのですが、
# 複数行に1つの式を書きたいときは以下のように行末に backslash(\) を置きます。
# backslash(\) の直後に来る改行は無視されます：

a = 1 + 3 \
* 4
puts(a.to_s)

# なお、文字列リテラルの中では改行が式の区切りとなることはありません：

s = "Let's talk about ...
  single,
  simple,
  sample."
puts(s)


