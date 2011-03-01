# desc: constructor 構築器

# ... [rule, 計算] の配列 ra_pairs を与えて、解析木に対し計算を施す。
# ra_pairs :abbrev: rule-action pairs

def rule_action(pterm, ra_pairs)
  if pterm.instance_of?(Branch)
    # pterm.rule に合致する action を ra_pairs からとってきて、
    # それに pterm.collection を与えて計算させる。
    action = get_action(pterm.rule, ra_pairs)
    action.call(pterm.collection)
  elsif pterm.instance_of?(Terminal)
    pterm.val
  end
end
def get_action(pterm_rule, ra_pairs)
  ra_pairs.each {|rule, action| return action if pterm_rule == rule }
  abort('Abort in get_action') # ここに制御が来ることはまずないだろう……。
end

