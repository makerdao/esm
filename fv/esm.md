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

Let's specify `fire`:

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

And now let's do `join`:

```act
behaviour join of ESM
interface join(uint256 wad)

types
  Pit : address
  Fired : uint256
  Total : uint256
  Usr_sum : uint256
  Bal_s : uint256
  Bal_d : uint256
  Allowance : uint256
  Owner : address
  Stopped : bool
  DSToken : address DSToken

storage
  gem |-> DSToken
  pit |-> Pit
  fired |-> Fired
  sum[CALLER_ID] |-> Usr_sum => Usr_sum + wad
  Sum |-> Total => Total + wad

storage DSToken
  balances[CALLER_ID] |-> Bal_s => Bal_s - wad
  balances[Pit] |-> Bal_d => Bal_d + wad
  owner_stopped |-> #WordPackAddrUInt8(Owner, Stopped)
  approvals[CALLER_ID][ACCT_ID] |-> Allowance => #if (CALLER_ID == ACCT_ID or Allowance == maxUInt256) #then Allowance #else Allowance - wad #fi

iff in range uint256
  Usr_sum + wad
  Total + wad
  Bal_s - wad
  Bal_d + wad

iff
  Fired == 0
  VCallValue == 0
  Stopped == 0
  (Allowance == maxUInt256) or (Allowance >= wad)
  VCallDepth < 1024

if
  CALLER_ID =/= Pit

calls
  DSToken.transferFrom
  ESM.add
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

End proofs from k-dss:

```
behaviour cage-surplus of End
interface cage()

for all

    Vat : address Vat
    Cat : address Cat
    Vow : address Vow
    Flapper : address Flapper
    Flopper : address Flopper
    FlapVat : address
    VowVat  : address

    Live : uint256
    When : uint256

    VatLive  : uint256
    CatLive  : uint256
    VowLive  : uint256
    FlapLive : uint256
    FlopLive : uint256

    CallerMay : uint256
    EndMayVat : uint256
    EndMayCat : uint256
    EndMayVow : uint256
    VowMayFlap : uint256
    VowMayFlop : uint256

    Dai_f : uint256
    Sin_v : uint256
    Dai_v : uint256
    Debt  : uint256
    Vice  : uint256
    Sin   : uint256
    Ash   : uint256

storage
  // whether CALLER_ID is an owner of End
  wards[CALLER_ID] |-> CallerMay => CallerMay
  // system liveness
  live             |-> Live      => 0
  // time of cage
  when             |-> When      => TIME
  // Vat that this End points to
  vat              |-> Vat       => Vat
  // cat that this End points to
  cat              |-> Cat       => Cat
  // Vow that this End points to
  vow              |-> Vow       => Vow


storage Vat
  // whether ACCT_ID is an owner of Vat
  wards[ACCT_ID]        |-> EndMayVat => EndMayVat
  // system status
  live                  |-> VatLive   => 0
  // dai assigned to Flapper
  dai[Flapper]          |-> Dai_f     => 0
  // dai assigned to Vow
  dai[Vow]              |-> Dai_v     => (Dai_v + Dai_f) - Sin_v
  // system debt assigned to Vow
  sin[Vow]              |-> Sin_v     => 0
  // total dai issued from the system
  debt                  |-> Debt      => Debt - Sin_v
  // total system debt
  vice                  |-> Vice      => Vice - Sin_v
  // whether Flapper can spend the resources of Flapper
  can[Flapper][Flapper] |-> _         => _


storage Cat
  // system liveness
  live           |-> CatLive   => 0
  //
  wards[ACCT_ID] |-> EndMayCat => EndMayCat


storage Vow
  // whether ACCT_ID is an owner of Vow
  wards[ACCT_ID] |-> EndMayVow => EndMayVow
  // Vat that this Vow points to
  vat            |-> VowVat    => VowVat
  // Flapper that this Vow points to
  flapper        |-> Flapper   => Flapper
  // Flopper that this Vow points to
  flopper        |-> Flopper   => Flopper
  // liveness flag
  live           |-> VowLive   => 0
  // total queued sin
  Sin            |-> Sin       => 0
  // total sin in debt auctions
  Ash            |-> Ash       => 0


storage Flapper
  // whether Vow is an owner of Flop
  wards[Vow] |-> VowMayFlap => VowMayFlap
  // dai token
  vat        |-> FlapVat    => FlapVat
  // liveness flag
  live       |-> FlapLive   => 0


storage Flopper
  // whether Vow is an owner of Flop
  wards[Vow] |-> VowMayFlop => VowMayFlop
  // liveness flag
  live       |-> FlopLive   => 0

iff

    VCallValue == 0
    VCallDepth < 1022
    Live == 1
    CallerMay == 1
    EndMayVat == 1
    EndMayCat == 1
    EndMayVow == 1
    VowMayFlap == 1
    VowMayFlop == 1

iff in range uint256

    Dai_v + Dai_f
    Debt - Sin_v
    Vice - Sin_v

if
    Dai_v + Dai_f > Sin_v
    Flapper =/= Vow
    Flapper =/= Vat
    Flopper =/= Vow
    Flopper =/= Vat
    Flopper =/= Flapper
    FlapVat == Vat
    VowVat  == Vat
    VowVat  =/= Vow
    FlapVat =/= Vow

calls
    Vat.cage
    Cat.cage
    Vow.cage-surplus
```
