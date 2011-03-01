# desc: 素数を標準出力に出す。それだけ。

dofile('primeseq.qs', @s)

nprime = 100
PrimeSeq:acc_times!( nprime - 1 )

puts(  PrimeSeq:seq.to_s  )

