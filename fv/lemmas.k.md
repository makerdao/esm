```k
rule X >=Int Y => notBool(X <Int Y)

syntax Int ::= "#WordPackAddrUInt8" "(" Int "," Int ")" [function]
rule #WordPackAddrUInt8(A, X) => X *Int pow160 +Int A
  requires #rangeAddress(A)
  andBool  #rangeUInt(8, X)

rule (X *Int pow160 +Int A) /Int pow160 => X
  requires #rangeAddress(A)
```
