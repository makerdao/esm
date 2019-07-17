Let's spec `full`:

```act
behaviour full of ESM
interface full()

types
  Zum : uint256
  Min : uint256

storage
  Sum |-> Zum
  min |-> Min

iff
  VCallValue == 0

returnsRaw #padToWidth(32, #asByteStack(bool2Word(Zum >=Int Min)))
```

It needs `returnsRaw` because of a bug in K.

Now `add`:

```act
behaviour add of ESM
interface add(uint256 x, uint256 y) internal

stack
  y : x : JMPTO : WS => JMPTO : x + y : WS

iff in range uint256
  x + y

iff
  VCallValue == 0

if
  #sizeWordStack(WS) <= 1000
```

`end.cage` hasn't been FV'd yet, so we can only FV `full` with `end.cage`
removed:

```
behaviour fire of ESM
interface fire()

types
  Fired : bool

storage
  fired |-> 0 => 1

iff
  Fired == 0

calls
  ESM.full

if
  #sizeWordStack(CD) == 0
```

so let's do `join`

```act
behaviour join of ESM
interface join(uint256 wad)

types
  Pit : address
  Fired : uint256
  Zum : uint256
  Usm : uint256
  Bal_s : uint256
  Bal_d : uint256
  Appr : uint256
  Owner : address
  Stopped : bool
  DSToken : address DSToken

storage
  pit |-> Pit
  fired |-> Fired
  sum[CALLER_ID] |-> Usm => Usm + wad
  Sum |-> Zum => Zum + wad

storage DSToken
  balances[CALLER_ID] |-> Bal_s => Bal_s - wad
  balances[Pit] |-> Bal_d => Bal_d + wad
  owner_stopped |-> #WordPackAddrUInt8(Owner, Stopped)
  approvals[CALLER_ID][ACCT_ID] |-> Appr => #if (CALLER_ID =/= ACCT_ID and Appr =/= maxUInt256) #then Appr - wad #else Appr #fi

iff in range uint256
  Usm + wad
  Zum + wad
  Bal_s - wad
  Bal_d + wad

iff
  Fired == 0
  VCallValue == 0
  Stopped == 0
  (Appr == maxUInt256) or (Appr >= wad)

if
  CALLER_ID =/= Pit

calls
  DSToken.transferFrom

```

Let's prove `DSToken.transferFrom`:

```act
behaviour transferFrom of DSToken
interface transferFrom(address src, address dst, uint wad)

types
  Bal_s     : uint256
  Bal_d     : uint256
  Allowance : uint256
  Owner     : address
  Stopped   : bool

storage
  balances[src]             |-> Bal_s => Bal_s - wad
  balances[dst]             |-> Bal_d => Bal_d + wad
  owner_stopped             |-> #WordPackAddrUInt8(Owner, Stopped)
  approvals[src][CALLER_ID] |-> Allowance => #if (src == CALLER_ID or Allowance == maxUInt256) #then Allowance #else Allowance - wad #fi

iff in range uint256
  Bal_s - wad
  Bal_d + wad

iff
  VCallValue == 0
  Stopped == 0
  (src == CALLER_ID or Allowance == maxUInt256) or (Allowance >= wad)

if
  src =/= dst

returns 1
```
