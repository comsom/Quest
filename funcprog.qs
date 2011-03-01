# desc: Quest による関数プログラミングの例 ... 関数の貼り合わせ。

# http://www.sampou.org/haskell/article/whyfp.html
# 「なぜ関数プログラミングは重要か」の
# 「3. 関数の貼り合せ」に現れるコードを Quest で表現する。

#---------------------------------------------------------------
# reduce

puts("\nreduce")

# (reduce f x) nil = x
# (reduce f x) (cons a l) = f a ((reduce f x) l)
fun reduce(f,iv)
  fun _(a)
    if a.empty? then iv
    else f(a[0], _(a[1..-1]))
    end
  end
end
# f は cons を, x は [] を置き換える。

# 配列の要素のいずれかが真であるか？　を計算する関数
anytrue? = reduce(fun(x,y) x or y end, false)
puts( 'anytrue? : ' ++ anytrue?([false,false,true,false]).to_s )   #=> true
# 配列の和を計算する関数
sum = reduce(fun(x,y) x+y end, 0)
puts( 'sum : ' ++ sum([2,3,5,7,11]).to_s )                   #=> 28

# リストの連結 append a b = reduce cons b a' をQuestで書く：
fun cons(x,y) [x] ++ y end
fun append(a,b) reduce(cons,b)(a) end
puts( 'append : ' ++ append([-2,-4],[7,9]).to_s )

# リストの各要素を2倍する関数を reduce で書くには？
# double_all = reduce double_and_cons nil
#   where double_and_cons n l = cons (2*n) l
fun double_and_cons(n,l) cons(2*n, l) end
double_all = reduce(double_and_cons, [])
puts( 'double_all : ' ++ double_all([3,5,6]).to_s )

# double_and_cons を分解する
# double_and_cons = f_and_cons double
#   where double n = 2*n
#         f_and_cons f el l = cons (f el) l
fun double(n) 2*n end
fun f_and_cons(f,el,l) cons(f(el), l) end
fun double_and_cons(n,l) f_and_cons(double, n, l) end
puts( 'double_and_cons : ' ++ double_and_cons(3,[5,10]).to_s )

# 関数合成 f_and_cons f = cons . f   ... cons の第一引数に合成する。
fun comb(f,g) fun(h,l) f(g(h), l) end end
fun f_and_cons(f,el,l) comb(cons, f)(el, l) end
puts( 'f_and_cons : ' ++ f_and_cons(double, 3,[5,10]).to_s )

#---------------------------------------------------------------
# redtree

# treeof X ::= node X  (listof (treeof X))

# ここでの tree は2つの要素を持つ：ラベルとサブツリーのリスト。
# サブツリーが空(nil)であれば、それは葉を表す。

puts("\nredtree")

space Tree init
  fun new(label,trees) @s end
  fun parent() @r:@p end
end

# 図示されている木は以下のように表せる。
tree = Tree:new(1,[Tree:new(2,[]),                 \
                   Tree:new(3,[Tree:new(4,[])])    \
                  ]                                \
               )

fun redtree(f,g,a)
  fun _(t)
    if    t.parent == Tree              then  f(t:label, _(t:trees))
    elsif t.parent == Array and t.any?  then  g(_(t[0]), _(t[1..-1]))
    elsif t.parent == Array             then  a
    else puts('Error'); quit()
    end
  end
end
# f は Tree を, g は cons を, a は [] を置き換える。

# ラベルの数値をすべて足す関数
add = fun(x,y) x+y end
sumtree = redtree(add, add, 0)
puts('sumtree : ' ++ sumtree(tree).to_s)

# ラベルのリストを作る関数
labels = redtree(cons, append, [])
puts('labels : ' ++ labels(tree).to_s)

