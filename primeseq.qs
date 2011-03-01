# desc: 素数の無限列(遅延リスト)を扱うライブラリ

space PrimeSeq init
  seq = [2]
  fun acc!()
    # n = seq[-1] + 1 から初めて、
    # seq のどの元でも割り切れない n が見つかるまで countup する。
    @p:seq = @p:seq ++ [acc_inner(seq[-1] + 1)]
  end
  fun acc_inner(n)
    if n.exist_divisible?(seq.select(fun(p) p*p<=n end))
    then acc_inner(n+1)
    else n
    end
  end
  fun getp(i)
    need = i - seq.length + 1
    if need > 0 then acc_times!(need) end
    seq[i]
  end
  fun acc_times!(n)
    if n>0 then acc!(); acc_times!(n-1) end
  end
end

on Integer do
  fun is_prime?()
    # @r が素なら true を、素でない場合は最小の素因数を返す。
    @r.is_prime_inner(0)
  end
  fun is_prime_inner(i)
    p = Toplevel:PrimeSeq:getp(i)   # Integer をたぐっても PrimeSeq は見えない。
    if    p*p > @r then true
    elsif @r%p==0  then false
    else                @r.is_prime_inner(i+1)
    end
  end
  fun lepf()    # abbrev: least prime factor 最小素因数
    # 計算方法は is_prime? のそれにそっくり。
    @r.lepf_inner(0)
  end
  fun lepf_inner(i)
    p = Toplevel:PrimeSeq:getp(i)
    if    p*p > @r then @r
    elsif @r%p==0  then p
    else                @r.lepf_inner(i+1)
    end
  end
  fun exist_divisible?(seq)
    seq.inject(false, fun(res, p)
      if @r % p == 0 then true else res end
    end)
  end
  fun isqrt()   @r.sqrt.to_i   end
end



# # test code
# 
# puts('acc_inner : ' ++ PrimeSeq:acc_inner(3).to_s)
# 
# PrimeSeq:acc!()
# PrimeSeq:acc!()
# PrimeSeq:acc!()
# PrimeSeq:acc!()
# puts('prime seq : ' ++ PrimeSeq:seq.to_s)
# 
# x = 17*37
# puts(x.to_s ++ ' is prime? : ' ++ x.is_prime?.to_s)
# puts('prime seq : ' ++ PrimeSeq:seq.to_s)
# 
# x = 1009 # 31
# puts(x.to_s ++ ' is prime? : ' ++ x.is_prime?.to_s)
# puts('prime seq : ' ++ PrimeSeq:seq.to_s)
