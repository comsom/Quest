# desc: 素数を標準出力に出す。それだけ。    ~/d11b/primes.dat に出力を貼った。

dofile('sample7.qs', @s)

nprime = 100
PrimeSeq:acc_times!( nprime - 1 )

puts(  PrimeSeq:seq.to_s  )

