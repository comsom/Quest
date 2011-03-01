# desc: クラスシステムの真似事。
# clsobj :abbrev: class and object

puts("\nclass-oid as a space")

space Rect init
  fun new(w,h) @s end
  fun area() @r:w * @r:h end
  @p = Base             # トップレベルの変数を使わないなら直接基底空間に繋いでよい。
end
r = Rect:new(10,8)
puts('r.area : ' ++ r.area.to_s)                  #=> 80

space Square init
  fun new(a)
    s = @p:@p:new(a,a)
    s:@p = Toplevel:Square   # 親空間の付け替え((R)によりSquareは見えなくなっている)。
    s
  end
  @p = Rect             # 継承の真似事。  ...(R)
end
s = Square:new(1111)
puts('s.area : ' ++ s.area.to_s)                 #=> 1234321




# vvv 以下のように、関数として定義することもできる vvv

puts("\nclass-oid as a function")

pi = 3.14
fun Circle(radius)
  fun perimeter() 2 * radius * pi end
  fun area() radius * radius * pi end
  @s
end

c = Circle(5)
puts('c.area : ' ++ c.area.to_s)        #  こちらの場合 c:area() と書いても同じ。

# ^^^ 関数として定義した場合、
# ^^^ メソッドに当たる関数がインスタンスにあたる空間を作るたびに作り直される。
# ^^^ ちょっと無駄がある。
