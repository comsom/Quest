# desc: Project Euler の問題を解いてみる。

# #------------------------------------------------------------
# puts("\nProject Euler Problem 1")
# 
# 1000 未満の、3または5の倍数になっている数の和を求めよ。
# 
# fun sum_3or5muls_below(n)
#   (1...n).inject(0, fun(sum, i)
#     sum + (if i%3==0 then i elsif i%5==0 then i else 0 end)
#   end)
# end
# puts('sum_3or5muls_below')
# puts('(10) : ' ++ sum_3or5muls_below(10).to_s)
# puts('(1000) : ' ++ sum_3or5muls_below(1000).to_s)
# 
# #------------------------------------------------------------
# puts("\nProject Euler Problem 2")
# 
# 1,2を初項とする Fibonacci 数列に現れる 4000000 以下の偶数の和を求めよ。
# 
# fun sum_evenfibs_notex(n, a,b)      # abbrev: not exceed
#   # 普通に全部足す。
#   if a > n then
#     0
#   elsif a%2==0 then
#     sum_evenfibs_notex(n, b,a+b) + a
#   else
#     sum_evenfibs_notex(n, b,a+b)
#   end
# end
# # 1,2,3,5,8,13,21,34,55,89,144
# puts('sum_evenfibs_notex')
# puts('(10) : '      ++ sum_evenfibs_notex(10,     1,2).to_s)      #=> 10
# puts('(150) : '     ++ sum_evenfibs_notex(150,    1,2).to_s)      #=> 188
# puts('(4000000) : ' ++ sum_evenfibs_notex(4000000,1,2).to_s)

#------------------------------------------------------------
puts("\nProject Euler Problem 3")

# 600851475143 の素因数の中で最大のものを求めよ。

dofile('sample7.qs', @s)  # 素数列ライブラリを持ってくる。

fun largest_prime_factor(n)
  p = n.lepf
  if p == n
  then n
  else largest_prime_factor(n/p)
  end
end

puts('largest_prime_factor')

puts('(12) : ' ++ largest_prime_factor(12).to_s)
puts('(210) : ' ++ largest_prime_factor(210).to_s)

x = 2*2*3*3*7*11*13*13*13
puts('(' ++ x.to_s ++ ') : ' ++ largest_prime_factor(x).to_s)

x = 600851475143
puts('(' ++ x.to_s ++ ') : ' ++ largest_prime_factor(x).to_s)

# qi で対話的に調べた結果 600851475143 == 71 * 839 * 1471 * 6857 がわかった。

