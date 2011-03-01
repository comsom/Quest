# desc: 12桁のパスワードの候補を5個生成する。

a = (0..9).map(fun(n) n.to_s end) ++ ('a'..'z').to_a
n = a.length

fun pswd()
  (1..12).inject('', fun(acc,i) acc ++ a[rand(n)] end)
end

(1..5).inject(nil, fun(i,j) puts( pswd() ) end)

