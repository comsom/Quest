# desc: 既存の空間に変数を追加する。

#---------------
# reverse の定義

on Array do
  fun reverse()
    if @r.empty? then []
    else @r[1..-1].reverse ++ [@r[0]]
    end
  end
end

puts('reverse : ' ++ (1..7).to_a.reverse.to_s)

# vvv 以下のように書いても動くが、この場合この関数の親はトップレベルになる vvv
# Array:reverse = fun()
#   if @r.empty? then []
#   else @r[1..-1].reverse ++ [@r[0]]
#   end
# end





#----------------
# times_do の定義

# Ruby の Integer#times メソッドにあたる関数。

on Integer do
  fun times_do(f) @r.times_do_inner(f,@r) end
  fun times_do_inner(f,n)
    if @r <= 0 then n
    else f(n-@r); (@r-1).times_do_inner(f,n)
    end
  end
  # fの引数(0...@r)が昇順に渡されるように inner を設けた。
end

5.times_do(fun(i) puts(i.to_s ++ '-th puts') end)

