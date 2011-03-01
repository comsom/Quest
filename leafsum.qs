# desc: 葉の値の和を計算する  ... 空間を型として使う。

space Leaf init
  fun new(x) @s end
end
space Branch init
  fun new(l,m) @s end
end

fun leaf_sum(tree)
  if    tree:@p == Leaf   then
    tree:x
  elsif tree:@p == Branch then
    leaf_sum(tree:l) + leaf_sum(tree:m)
  end
end

tree = Branch:new(Branch:new(Leaf:new(3), Leaf:new(4)),  \
                  Leaf:new(5))
puts('leaf_sum : ' ++ leaf_sum(tree).to_s)

