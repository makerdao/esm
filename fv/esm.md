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
