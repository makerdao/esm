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
