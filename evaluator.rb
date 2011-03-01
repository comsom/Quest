# desc: evaluator 評価器

# Array の形で書かれたS式を評価・実行する。

require 'qerror'

#-------------------------------------
# vvv dofile のために予め用意しておく vvv

require 'gquest'
include GQuest

require 'lexer'

require 'fparser'
include Parser
require 'constructor'

f = File::open('redposs.dat', 'r')
redposs = Marshal.load(f)
f.close
set_grammar!( RULESET, START_SYMBOL, redposs )

#-----------------------------------
# atom : iden, spcs, integer, string
# oper : +,-,*,/,%,=

class Array
  def car
    self[0]
  end
  def cdr
    self[1..-1]
  end
end

#-------------------------------------------------------------------------------
# S式の評価関数
#-------------------------------------------------------------------------------

def s_eval(sexp, cns) # cns :abbrev: Current NameSpace
  if atom?(sexp)
    if literal?(sexp)# or spcs?(sexp)
      # [literal or spcs の返値]
      sexp
    elsif iden?(sexp)
      # [変数の参照]
      lookup(sexp, cns)
    else
      QError.new('Error in s_eval : atom : ' + sexp.inspect)
    end
  elsif list?(sexp)
    car_val = s_eval(sexp.car, cns)
    if car_val.is_a?(QError)
      car_val
    elsif substitution?(car_val)
      # [代入の処理]
      s_substitution(sexp, cns)
    elsif if_expr?(car_val)
      # [if の処理]
      s_if(sexp, cns)
    elsif fun?(car_val)
      # [fun の生成]
      s_fun(sexp, cns)
    elsif application?(car_val)
      # [fun の適用]
      s_application(car_val, sexp, cns)
    elsif prim_fun?(car_val)
      # [prim_fun の適用]
      s_prim_fun(car_val, sexp, cns)
    elsif space?(car_val)
      # [space の生成]
      s_space(sexp, cns)
    elsif on_do?(car_val)
      # [on_do 式]
      s_on_do(sexp, cns)
    elsif colon?(car_val)
      # [colon(:) (取り出し)の処理]
      s_colon(sexp, cns)
    elsif dot?(car_val)
      # [dot(.) (呼び出し)の処理]
      s_dot(sexp, cns)
    elsif array_new?(car_val)
      # [Array の生成]
      s_array_new(sexp, cns)
    elsif array_ref?(car_val)
      # [Array の参照]
      s_array_ref(sexp, cns)
    elsif range?(car_val)
      # [range の生成]
      s_range(car_val, sexp, cns)
    else
      QError.new('Error in s_eval : list : ' + sexp.inspect +
                       ' : car_val : ' + car_val.inspect)
    end
  else
    QError.new('Error : sexp is neither atom nor list : ' + sexp.inspect)
  end
end
def s_substitution(sexp, cns)
  if iden?(sexp[1])
    # [形式] sexp = [:'=', <iden>, <sexp>]
    val = s_eval(sexp[2], cns)
    i   = sexp[1]
    if val.is_a?(QError)
      val
    elsif not iden?(i)
      QError.new('Error : not iden : ' + i.inspect)
    else
      cns[i] = val
    end
  elsif list?(sexp[1]) and sexp[1][0]==:':'
    # [形式] sexp = [:'=', [:':',<sexp>,<iden>], <sexp>]
    sp  = s_eval(sexp[1][1], cns)
    i   = sexp[1][2]
    val = s_eval(sexp[2], cns)
    if sp.is_a?(QError)
      sp
    elsif not iden?(i)
      QError.new('Error : not iden : ' + i.inspect)
    elsif val.is_a?(QError)
      val
    else
      sp[i] = val
    end
  else
    QError.new('Error in substitution? : ' + sexp.inspect)
  end
end
def s_if(sexp, cns)
  # [形式] sexp = [:if, [<sexp>, <sexp>+]+, [:else, <sexp>+]?] = [:if, (A), (B)]
  val = false
  sexp.cdr.each{|cs|
    cond  = cs.car
    sexps = cs.cdr
    if sexp?(cond) and cond != :else
      # [(A)の処理]
      cond_val = s_eval(cond, cns)
      if cond_val == true
        val = sexps.seq_eval( Space.new({:@p => cns}) )
        break
      elsif cond_val == false
        nil # 何もしない ... 次の clause へ。
      else
        val = QError.new('Error : conditional must be true/false : ' +
                         cond_val.inspect)
        break
      end
    elsif cond == :else
      # [(B)の処理]
      val = sexps.seq_eval( Space.new({:@p => cns}) )
      break
    else
      val = QError.new('Error in s_if : ' + sexp)
      break
    end
  }
  val
end
def sexp?(s)
  atom?(s) or list?(s)
end
def s_fun(sexp, cns)
  # [形式] sexp = [:fun, <params>, <sexps>]
  Fun.new(cns, sexp[1], sexp[2])
end
def s_application(car_val, sexp, cns)
  # [形式] sexp = [(fun値に評価されるもの), <arg>*]
  argl =  sexp.cdr.map{|s| s_eval(s, cns) }
  pms = car_val.params
  if pms.length != argl.length
    return QError.new("Error : arity is #{pms.length} != given #{argl.length}")
  end
  alist = [[:@p, car_val.parent]] + [pms, argl].transpose
  new_ns = Space.new(Hash[ *(alist.inject([]){|a,b|a+b}) ])
  car_val.sexps.seq_eval(new_ns)
end
def s_prim_fun(car_val, sexp, cns)
  # [形式] sexp = [(PrimFun値に評価されるもの), <arg>*]
  argl = sexp.cdr.map{|s| s_eval(s,cns) }
  e = argl.select{|v| v.is_a?(QError) }
  return e[0] if e.any?
  car_val.call(argl)
end
def s_space(sexp, cns)
  # [形式] sexp = [:space, <sexps>]
  sp = Space.new({ :@p => cns}) # SP_BASE })
  sexp[1].seq_eval(sp)
  sp
end
def s_on_do(sexp, cns)
  # [形式] sexp = [:on_do, <sexp>, <sexp>+]
  sp = s_eval(sexp[1], cns)
  return sp if sp.is_a?(QError)
  return QError.new('Error : not space : ' + sp.inspect) unless sp.is_a?(Space)
  sexp[2..-1].seq_eval(sp)
end
def s_colon(sexp, cns)
  # [形式] sexp = [:':', <sexp>, <iden>]
  sp = s_eval(sexp[1], cns)
  return sp if sp.is_a?(QError)
  return QError.new('Error : not space : ' + sp.inspect) unless sp.is_a?(Space)
  i  = sexp[2]
  return QError.new('Error : not iden : ' + sexp.inspect) unless iden?(i)
  sp[i] # lookup(i, sp)
end
def s_dot(sexp, cns)
  # [形式] [:'.', <sexp>, <iden>, <argl>*]
  # space の取り出し
  val1 = s_eval(sexp[1], cns)
  return val1 if val1.is_a?(QError)
  sp = if val1.is_a?(Space)
         val1
       else
         parent_of(val1)
       end
  return sp if sp.is_a?(QError)
  # 関数の取り出し
  i = sexp[2]
  return QError.new('Error : not iden : ' + i.inspect) unless iden?(i)
  fun = lookup(i, sp)
  # 引数リスト argl の用意
  argl = sexp[3..-1].map{|s| s_eval(s, cns) }
  e = argl.select{|v| v.is_a?(QError) }
  return e[0] if e.any?
  # dot(.) 適用
  if fun.is_a?(Fun)
    pms = fun.params
    if pms.length != argl.length
      return QError.new("Error : arity is #{pms.length} " +
                        "!= given #{argl.length}")
    end
    alist = [[:@p,fun.parent],[:@r,val1]]+[pms,argl].transpose
    new_sp = Space.new(Hash[ *(alist.inject([]){|a,b|a+b}) ])
    val = fun.sexps.seq_eval(new_sp)
    new_sp.delete(:@r) # sexps 実行後に receiver を消す。
    val
  elsif fun.is_a?(PrimFun)
    if fun.arity == 2
      fun.call(val1, argl)
    elsif fun.arity == 1    # 
      puts('Warning : unexpected form of calling : ' + [val1,argl].inspect)
      fun.call(argl)
    else
      QError.new("Error in s_dot(.)")
    end
  else
    QError.new("Error : not fun : #{fun.inspect} : #{sexp.inspect}")
  end
end
def s_array_new(sexp, cns)
  # [形式] sexp = [:'[new]', <sexp>*]
  val = sexp.cdr.map{|s| s_eval(s, cns) }
  e = val.select{|v| v.is_a?(QError) }
  return e[0] if e.any?
  val
end
def s_array_ref(sexp, cns)
  # [形式] sexp = [:'[ref]', <sexp>, <sexp>]
  a = s_eval(sexp[1], cns)
  r = s_eval(sexp[2], cns)
  if not a.is_a?(Array)
    QError.new('Error : not Array : ' + a.inspect) 
  elsif a.is_a?(QError)
    a
  elsif (not r.is_a?(Integer)) and (not r.is_a?(QRange))
    QError.new('Error : invalid ref : ' + r.inspect)
  elsif r.is_a?(QError)
    r
  else
    a[r]
  end
end
def s_range(car_val, sexp, cns)
  # [形式] sexp = [(:'..'または:'...'), <sexp>, <sexp>]
  s = s_eval(sexp[1],cns)
  e = s_eval(sexp[2],cns)
  f = (car_val == :'..' ? false : true)
  QRange.new(s,e,f)
end



#-------------------------------------------------------------------------------
# S式のタイプ判別用の関数、 seq_eval, parent_of, lookup, lookup_space
#-------------------------------------------------------------------------------

class Array
  def seq_eval(space)
    # new_ns の上で self (sexps) を順に評価していき、最後に評価された式の値を返す。
    val = nil
    self.each{|sexp|
      val = s_eval(sexp, space)
      return val if val.is_a?(QError)
    }
    val
  end
end
def parent_of(val)
  # space でない object に対し、その親空間を返す。
  # (Hash にまとめた方が良いかも……) (各 object を class にして parent_of を持たせる)
  if val.is_a?(Integer)
    SP_INTEGER
  elsif val.is_a?(Numeric)
    SP_REAL
  elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
    SP_BOOL
  elsif val.is_a?(NilClass)
    SP_NIL
  elsif val.is_a?(Array)
    SP_ARRAY
  elsif val.is_a?(QRange)
    SP_RANGE
  elsif val.is_a?(String)
    SP_STRING
  elsif val.is_a?(Fun)
    SP_FUNCTION
  else
    QError.new('Error in parent_of : parent not found : ' + val.inspect)
  end
end

def atom?(sexp)
  sexp.is_a?(Symbol) or sexp.is_a?(Numeric) or sexp.is_a?(String) or
    sexp.is_a?(TrueClass) or sexp.is_a?(FalseClass) or sexp.is_a?(NilClass)
end
def literal?(sexp)
  sexp.is_a?(Numeric) or sexp.is_a?(String) or
    sexp.is_a?(TrueClass) or sexp.is_a?(FalseClass) or sexp.is_a?(NilClass)
end
def iden?(sexp)
  sexp.is_a?(Symbol)
end
def lookup(iden, space)
  if space.is_a?(QError)
    space
  elsif space.has_key?(iden)
    space[iden]
  else
    lookup(iden, space[:@p])
  end
end

def list?(sexp)
  sexp.is_a?(Array)
end
def substitution?(val)
  val == :'='
end
def lookup_space(iden, space)
  if not space.is_a?(Space)
    QError.new('QError in lookup_space : space not found')
  elsif space.has_key?(iden)
    space
  else
    lookup_space(iden, space[:@p])
  end
end
def if_expr?(val)
  val == :if
end
def fun?(val)
  val == :fun
end
def application?(val)
  val.is_a?(Fun)
end
def prim_fun?(val)
  val.is_a?(PrimFun)
end
def space?(val)
  val == :space
end
def on_do?(val)
  val == :on_do
end
def dot?(val)
  val == :'.'
end
def colon?(val)
  val == :':'
end
def array_new?(val)
  val == :'[new]'
end
def array_ref?(val)
  val == :'[ref]'
end
def range?(val)
  val == :'..' or val == :'...'
end



#-------------------------------------------------------------------------------
# Quest で扱うオブジェクトのクラス
#-------------------------------------------------------------------------------

class QRange < Range
  def initialize(s,e,f)
    super(s,e,f)
  end
end

class Space < Hash
  attr_reader :name
  def initialize(hash, name='Space')
    hash.each{|k,v| self[k]=v }
    self[:@s] = self
    @name = name
    self.default = QError.new('Error : iden not found')
  end
  def inspect
    s = self.map{|k,v|
      if k == :@s
        '@s'
      elsif v.is_a?(Space)
        "#{k.to_s}=#{v.inspect_inner}"
      else
        "#{k.to_s}=#{v.inspect}"
      end
    }.join('; ')
    '${ ' + s + ' }'                # space の頭には $ を付ける。
  end
  # vvv 「space の中の space」までは表示を許す
  # vvv (「表示が循環して止まらん」を防ぐため、2段までで止める)。
  def inspect_inner
    s = self.map{|k,v|
      if k == :@s
        '@s'
      elsif v.is_a?(Space)
        "#{k.to_s}=$#{v.name}"      # space の頭には $ を付ける。
      else
        "#{k.to_s}=#{v.inspect}"
      end
    }.join('; ')
    '${ ' + s + ' }'
  end
end

class Fun
  attr_reader :parent, :params, :sexps
  def initialize(parent, params, sexps) # parent :abbrev: parent namespace
    @parent = parent
    @params = params
    @sexps  = sexps
  end
  def inspect
    "fun(#{params.map{|p|p.to_s}.join(',')})"
  end
end

# vvv 見た目の調整 vvv

class PrimFun < Proc
  def initialize(show, &body)
    @show = show
    super(&body)
  end
  def inspect
    'PrimFun' # @show
  end
end

class Symbol
  def inspect
    '`(' + self.to_s + ')'     # backquote(`) は quote の意味。
  end
end

#-------------------------------------------------------------------------------
# SP_BASE などの空間を作る
#-------------------------------------------------------------------------------

def bop_primfun(str, cls, &block) # bop :abbrev: binary operator
  PrimFun.new(str) {|argl|
    # (arity check は入れない ... (2+) などと書けば parse error になる)
    x,y = argl
    if    not x.is_a?(cls)
      QError.new("Error : not #{cls.inspect} : " + x.inspect)
    elsif not y.is_a?(cls)
      QError.new("Error : not #{cls.inspect} : " + y.inspect)
    else
      block.call(x,y)
    end
  }
end

#------------
# SP_BASE
#------------
h = {
  # (1) 文法と結びついた PrimFun ... arity check は入れてない。

  :'+' => bop_primfun('+', Numeric) {|x,y| x+y },
  :'-' => bop_primfun('-', Numeric) {|x,y| x-y },
  :'*' => bop_primfun('*', Numeric) {|x,y| x*y },
  :'/' => bop_primfun('/', Numeric) {|x,y|
    y==0 ? QError.new(%[Error : / : zero division]) : x/y
  },
  :'%' => bop_primfun('%', Numeric) {|x,y|
    y==0 ? QError.new(%[Error : % : zero division]) : x%y
  },

  :'<='  => PrimFun.new('<=')   {|argl| argl[0] <= argl[1] },
  :'>='  => PrimFun.new('>=')   {|argl| argl[0] >= argl[1] },
  :'<'   => PrimFun.new('<')    {|argl| argl[0] <  argl[1] },
  :'>'   => PrimFun.new('>')    {|argl| argl[0] >  argl[1] },
  :'=='  => PrimFun.new('==')   {|argl| argl[0] == argl[1] },
  :'!='  => PrimFun.new('!=')   {|argl| argl[0] != argl[1] },

  :'='   => :'=',

  :'++'  => PrimFun.new('++') {|argl|
    x,y = argl
    if (x.is_a?(Array) and y.is_a?(Array)) or
        (x.is_a?(String) and y.is_a?(String))
      x + y
    elsif not (x.is_a?(Array) and y.is_a?(Array))
      QError.new("Error : Array : #{x.inspect} ++ #{y.inspect}")
    elsif not (x.is_a?(String) and y.is_a?(String))
      QError.new("Error : String : #{x.inspect} ++ #{y.inspect}")
    else
      abort('Error in ++') # ここに制御が来ることはない。
    end
  },
  :'u+'  => PrimFun.new('u+') {|argl|
    x = argl[0]
    x.is_a?(Numeric) ? (+ x) : QError.new('Error : not numeric : ' + x.inspect)
  },
  :'u-'  => PrimFun.new('u-') {|argl|
    x = argl[0]
    x.is_a?(Numeric) ? (- x) : QError.new('Error : not numeric : ' + x.inspect)
  },

  :'.'   => :'.',
  :':'   => :':',
  :'[new]'   => :'[new]',
  :'[ref]'   => :'[ref]',
  :'..'   => :'..',
  :'...'   => :'...',

  :not   => PrimFun.new('not')   {|argl| not argl[0] },
  :and   => PrimFun.new('and')   {|argl| argl[0] and argl[1] },
  :or    => PrimFun.new('or')    {|argl| argl[0] or  argl[1] },

  :if    => :if,
  :fun   => :fun,
  :space => :space,
  :on_do => :on_do,

  # (2) 普通の関数呼び出し形式で呼ぶ PrimFun
  :puts  => PrimFun.new('puts') {|argl|
    if argl.length != 1
      QError.new("Error : arity is 1 != given #{argl.length}")
    else
      s = argl[0]
      if not s.is_a?(String)
        QError.new('Error : not String : ' + s.inspect)
      else
        puts(s)
      end
    end
  },
  :quit  => PrimFun.new('quit') {|argl| exit },
  :dofile => PrimFun.new('dofile') {|argl|
    if argl.length != 2
      QError.new("Error : arity is 2 != given #{argl.length}")
    else
      filename, space = argl
      if not filename.is_a?(String)
        QError.new('Error : not String : ' + filename.inspect)
      else
        code = File::open(filename, 'r').read
        tokenseq = eliminate( match_action( code, PAIRS ) )
        pterm = the_completed_pterm( parse( tokenseq ) )
        if pterm.is_a?(QError)
          pterm
        else
          sexps = rule_action(pterm, RA_PAIRS)
          val = sexps.seq_eval(space)
          if val.is_a?(QError)
            val
          else
            space
          end
        end
      end
    end
  },
  :rand => PrimFun.new('rand') {|argl|
    if argl.length != 1
      QError.new("Error : arity is 1 != given #{argl.length}")
    else
      rand(argl[0])
    end
  },

  # (3) dot(.) 呼び出しで呼ぶ PrimFun
  :to_s  => PrimFun.new('to_s') {|recv, argl| recv.inspect }, # 何でも文字列表示
  :in? => PrimFun.new('in?') {|recv, argl|
    if argl.length != 1
      val = QError.new("Error : arity is 1 != given #{argl.length}")
    else
      ary = argl[0]
      if not ary.is_a?(Array)
        QError.new('Error : not Array : ' + ary.inspect)
      else
        ary.include?(recv)
      end
    end
  },
}
SP_BASE = Space.new(h, 'Base')
SP_BASE[:Base] = SP_BASE

#------------
# SP_INTEGER
#------------
h = {
  :abs    => PrimFun.new('abs')    {|recv, argl| recv.abs        },
  :sqrt   => PrimFun.new('sqrt')   {|recv, argl| Math.sqrt(recv) },
  :to_f   => PrimFun.new('to_f')   {|recv, argl| recv.to_f       },
  :parent => PrimFun.new('parent') {|recv, argl| SP_INTEGER      },
  :@p => SP_BASE,
}
SP_INTEGER = Space.new(h, 'Integer')
SP_BASE[:Integer] = SP_INTEGER

#------------
# SP_REAL
#------------
h = {
  :abs    => PrimFun.new('abs')    {|recv, argl| recv.abs        },
  :sqrt   => PrimFun.new('sqrt')   {|recv, argl| Math.sqrt(recv) },
  :to_i   => PrimFun.new('to_i')   {|recv, argl| recv.to_i       },
  :parent => PrimFun.new('parent') {|recv, argl| SP_REAL         },
  :@p => SP_BASE,
}
SP_REAL = Space.new(h, 'Real')
SP_BASE[:Real] = SP_REAL

#------------
# SP_BOOL
#------------
h = {
  :parent => PrimFun.new('parent') {|recv, argl| SP_BOOL },
  :@p => SP_BASE,
}
SP_BOOL = Space.new(h, 'Bool')
SP_BASE[:Bool] = SP_BOOL

#------------
# SP_NIL
#------------
h = {
  :parent => PrimFun.new('parent') {|recv, argl| SP_NIL },
  :@p => SP_BASE,
}
SP_NIL = Space.new(h, 'Nil')
SP_BASE[:Nil] = SP_NIL

#------------
# SP_ARRAY
#------------
h = {
  # :to_s   => PrimFun.new('to_s')   {|recv, argl| recv.inspect },
  :empty? => PrimFun.new('empty?') {|recv, argl| recv.empty?  },
  :any?   => PrimFun.new('any?')   {|recv, argl| recv.any?    },
  :length => PrimFun.new('length') {|recv, argl| recv.length  },
  :map => PrimFun.new('map') {|recv, argl|
    fun = argl[0]
    if fun.is_a?(PrimFun)
      recv.map{|x| fun.call([x]) }
    elsif fun.is_a?(Fun)
      if fun.params.length != 1
        QError.new('Error : arity must be 1 : ' + fun.inspect)
      else
        recv.map {|x|
          alist = [[:@p, fun.parent], [fun.params[0], x]]
          new_ns = Space.new(Hash[ *(alist.inject([]){|a,b|a+b}) ])
          fun.sexps.seq_eval(new_ns)
        }
      end
    else
      QError.new('Error : not fun : ' + fun.inspect)
    end
  },
  :select => PrimFun.new('select') {|recv, argl|
    fun = argl[0]
    if fun.is_a?(PrimFun)
      recv.select{|x| fun.call([x]) }
    elsif fun.is_a?(Fun)
      if fun.params.length != 1
        QError.new('Error : arity must be 1 : ' + fun.inspect)
      else
        recv.select {|x|
          alist = [[:@p, fun.parent], [fun.params[0], x]]
          new_ns = Space.new(Hash[ *(alist.inject([]){|a,b|a+b}) ])
          fun.sexps.seq_eval(new_ns){|s| s_eval(s, new_ns) }
        }
      end
    else
      QError.new('Error : not fun : ' + fun.inspect)
    end
  },
  :inject => PrimFun.new('inject') {|recv, argl|
    iv, fun = argl          # iv :abbrev: initial value
    if fun.is_a?(PrimFun)
      recv.inject(iv) {|acc,x| fun.call([acc,x]) }
    elsif fun.is_a?(Fun)
      if fun.params.length!=2
        QError.new('Error : arity must be 2 : ' + fun.inspect) 
      else
        recv.inject(iv) {|acc,x|
          alist = [[:@p, fun.parent]] + [fun.params, [acc,x]].transpose
          new_ns = Space.new(Hash[ *(alist.inject([]){|a,b|a+b}) ])
          fun.sexps.seq_eval(new_ns)
        }
      end
    else
      QError.new('Error : not fun : ' + fun.inspect)
    end
  },
  :join => PrimFun.new('join') {|recv, argl|
    sep = argl[0]
    recv.join(sep)
  },
  :parent => PrimFun.new('parent')  {|recv, argl| SP_ARRAY },
  :@p => SP_BASE,
}
SP_ARRAY = Space.new(h, 'Array')
SP_BASE[:Array] = SP_ARRAY

#------------
# SP_RANGE
#------------
g = {
  # :to_s   => h[:to_s],
  :map    => h[:map],
  :select => h[:select],
  :inject => h[:inject],
  :to_a   => PrimFun.new('to_a')    {|recv, argl| recv.to_a },
  :parent => PrimFun.new('parent')  {|recv, argl| SP_RANGE  },
  :@p => SP_BASE,
}
SP_RANGE = Space.new(g, 'Range')
SP_BASE[:Range] = SP_RANGE

#------------
# SP_STRING
#------------
h = {
  :parent => PrimFun.new('parent')  {|recv, argl| SP_STRING },
  :@p => SP_BASE,
}
SP_STRING = Space.new(h, 'String')
SP_BASE[:String] = SP_STRING

#-------------
# SP_FUNCTION
#-------------
h = {
  :parent_space => PrimFun.new('parent_space') {|recv, argl| recv.parent },
  :params => PrimFun.new('params')  {|recv, argl| recv.params },
  # :exprs  => PrimFun.new('exprs')   {|recv, argl| recv.exprs }, まだ定義しない
  :parent => PrimFun.new('parent')  {|recv, argl| SP_FUNCTION },
  :@p => SP_BASE,
}
SP_FUNCTION = Space.new(h, 'Function')
SP_BASE[:Function] = SP_FUNCTION

#----------------
# SP_TOPLEVEL
#----------------
h = {
  :@p     => SP_BASE,
}
SP_TOPLEVEL = Space.new(h, 'SP_TOPLEVEL')
SP_BASE[:Toplevel] = SP_TOPLEVEL
























#-------------------------------------------------------------------------------
# test code
#-------------------------------------------------------------------------------

# if $0 == __FILE__
# 
#   #----------------------------
#   puts;puts('Evaluator : test')
# 
#   def put_seq_eval(sexps)
#     puts
#     sexps.each{|sexp|
#       puts(sexp.inspect)
#       puts('s_eval #=> ' + s_eval(sexp,SP_TOPLEVEL).inspect)
#     }
#   end
# 
#   put_seq_eval([[:'=', :ary, [:'[new]', 'single', 'simple', 'sample']],
#                 [:'[ref]', :ary, 1],
#                ])
# 
#   put_seq_eval([[:'.', [:'[new]', 2,3,5,7,11], :map, :puts]])
#   put_seq_eval([[:'.', [:'[new]', 2,3,5,7,11], :map, [:fun,[:x],[[:*,:x,:x]]]]])
# 
#   put_seq_eval([[:'.', [:'[new]', 1,3,5,7], :inject, 0, :'+']])
#   put_seq_eval([[:'.', [:'[new]', 1,3,5,7], :inject, 1,
#                  [:fun,[:x,:y],[[:'*',:x,:y]]]
#                ]])
# 
#   put_seq_eval([[:'...', 1,5]])
#   put_seq_eval([[:'[ref]', [:'[new]',1,6,2,8,0,3], [:'..',2,-1]]])
#   put_seq_eval([[:'.', [:'..', 1,20], :map, [:fun,[:x],[[:%,20,:x]]]]])
# 
#   exit
# end







if $0 == __FILE__

  #----------------------------
  puts;puts('Evaluator : test')

  def put_seq_eval(sexps)
    puts
    sexps.each{|sexp|
      puts(sexp.inspect)
      puts('s_eval #=> ' + s_eval(sexp,SP_TOPLEVEL).inspect)
    }
  end

  # date: 8;2011/2/25 (fri)
  put_seq_eval([[:on_do, :Integer,
                 [:'=', :sq, [:fun, [], [[:'*', :@r, :@r]]]],
                 [:'=', :top, [:fun, [:s], [[:'++', :s, [:'.',:@r,:to_s]]]]],
                ],
                [:'.', 22, :sq],
                [:'.', 7, :top, 'lucky ']
               ])
  exit

  # date: 8;2011/2/22 (tue)
  put_seq_eval([[:space, []]])
  put_seq_eval([[:'++', 'simple', 'sample']])
  put_seq_eval([[:'=', :ntimes, [:fun, [:s,:n], [
                 [:if,
                  [[:>, :n, 1], [:'++', [:ntimes, :s, [:-,:n,1]], :s]],
                  [:else,       :s],
                 ]
                ]]],
                [:ntimes, 'turntimber ', 3]
               ])
  #exit

  put_seq_eval([2])
  put_seq_eval([[:*, [:%, 19, 7], [:+, 1, 3]]])
  put_seq_eval([[:'=', :x, 3], [:'=', :y, [:+, :x, 1]], [:%, 13, :y]])
  puts('SP_TOPLEVEL : ' + SP_TOPLEVEL.inspect)
  
  put_seq_eval([#[:'=', :tmp, :x],
                [:if, [true,
                 [:'=', :x, 'simple'],
                 [:'=', :z, 'sample '],
                 [:'=', :cat, [:*, [:+, :x, :z], :y]],
                ]],
                :x,
                #[:'=', :x, :tmp],
               ])
  # ^^^ if の then, else 節は sexps の形にしてある ^^^
  put_seq_eval([[:if,
                [false, [:puts, "I won't be puts."]],
                [:else, [:puts, "I'll be puts."]]
               ]])
  puts('SP_TOPLEVEL : ' + SP_TOPLEVEL.inspect)
  
  puts; puts('make fun and apply fun')
  put_seq_eval([[:'=', :sq_sum,
               [:fun, [:x,:y],
                [[:+, [:*,:x,:x], [:*,:y,:y]]]
               ]
              ],
              [:sq_sum, 10, :x]
             ])
  put_seq_eval([[:'=', :dist,
                 [:fun, [:x,:y],
                  [[:if,
                    [[:<, :x, :y], [:-, :y, :x]],
                    [:else, [:-, :x, :y]]
                  ]]
                 ]
                ],
                [:dist, :x, :y]
               ])
  put_seq_eval([[:'=', :gcd,
                 [:fun, [:a, :b],
                  [[:'=', :r, [:%, :a, :b]],
                   [:if,
                    [[:==, :r, 0], :b],
                    [:else, [:gcd, :b, :r]]
                   ]
                  ]
                ]],
                [:gcd, 18, 24],
                [:gcd, 3315, 3795], #=> 15 (3*5*13*17 と 3*5*11*23 の最大公約数)
                # :a,:b => Error in lookup
               ])
  
  put_seq_eval([[:'=', :adder, [[:fun, [:n],   # application of vvv
                 [[:fun, [:i], [[:'=!', :n, [:'+', :n, :i]]]]]
                ], 5]],
                [:adder, 11],
                [:adder, 22],
               ])
  exit                       # ^^^遠方代入(=!)を近所代入(=)に変えると意味が変わる。

  put_seq_eval([[:'=', :S, [:space, [
                 [:'=', :a, 9],
                 [:'=', :f, [:fun, [], [[:*, :a, :a]]]]
                ]]],
                [:':', :S, :a],
                [[:':', :S, :f]],
                [:':', :S, :f],
               ])
  put_seq_eval([[:'=', :Rect, [:space, [
                 [:'=', :@p, [:':',:@p,:@p]], # @p = @p:@p (SP_BASE)
                 [:'=',:area,[:fun,[],[[:*, [:':',:@r,:w],[:':',:@r,:h]]]]],
                 [:'=', :new, [:fun, [:w,:h], [:@s]]]
                ]]],
                [:'=', :r, [[:':', :Rect, :new], 3,5]],
                [:'.', :r, :area]
               ])
  puts('SP_TOPLEVEL : ' + SP_TOPLEVEL.inspect)
  # vvv @p=Rect してから new=fun(a)...end すると、
  # vvv Rect.new に fun(a) が代入されてしまう ... 期待通りではない！
  # vvv (代入(=)は @s の外側にも影響しうる ... 定義(=)と代入(=!)に分けよう！)
  # vvv てなわけで逆順(new=fun(a)...end してから @p=Rect)にした。
  put_seq_eval([[:'=', :Square, [:space, [
                 [:'=', :@p, :Rect],
                 [:'=', :new, [:fun, [:a], [
                  [:'=', :sp, [[:':',[:':',:@p,:@p],:new],:a,:a]],
                  [:'=', [:':',:sp,:@p], :@p],
                  :sp,
                  # :@p, # debugwrite
                 ]]],
                ]]],
                [:'=', :s, [[:':', :Square, :new], 4]],
                [:'.', :s, :area]
               ])

  put_seq_eval([[:'.', 789, :to_s]])
  put_seq_eval([[:'=', [:':', :Integer, :calc_sq],
                 [:fun, [], [[:*, :@r, :@r]]]
                ],
                [:'.', 11, :calc_sq]
               ])

  exit
  # vvv set_grammar あたりが走らなくなっとる。





  require 'lexer'
  require 'fparser'
  include Parser
  require 'constructor'
  require 'grammar'

  #----------------------------------------------------------------------------
  puts;puts('QuestSimple : tokenize, parse, construct, and eval the code.')

  include GQuestSimple
  set_grammar!( RULESET, START_SYMBOL )

  def put_tpce(code) # tpce :abbrev: Tokenize Parse Construct Evaluate
    # 一つの code に対する test にけっこう行数がかかるので method にまとめた。
    puts
    puts('code : ' + code.inspect)
    tokenseq = match_action(code, PAIRS)
    puts('match_action #=> ' + tokenseq.inspect)
    tokenseq = eliminate( tokenseq )
    poss_ary = parse(tokenseq)
    # puts('parse #=>' + poss_ary.inspect) # 出力がデカいので commentout
    pterm = the_completed_pterm(poss_ary)
    sexps = rule_action(pterm, RA_PAIRS)
    puts('rule_action #=> ' + sexps.inspect)
    sexps.each{|sexp|
      puts("s_eval(#{sexp.inspect}) : " + s_eval(sexp,SP_TOPLEVEL).inspect)
    }
  end

  put_tpce( '1 + 1' )
  # put_tpce( '4 * (-10 + -70) / 32' )               #=> error
  put_tpce( '4 * (10 + 70) / 64' )

  put_tpce( 'a=6; a*a' )
  put_tpce( "structure = 9
             and = 4
             interpretation = 5
             of = 2
             computer = 7
             programs = 2
             structure * and - interpretation / of + computer % programs" )
end
