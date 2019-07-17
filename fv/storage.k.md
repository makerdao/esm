ESM storage:

```k
syntax Int ::= "#ESM.pit" [function]
rule #ESM.pit => 2

syntax Int ::= "#ESM.min" [function]
rule #ESM.min => 3

syntax Int ::= "#ESM.fired" [function]
rule #ESM.fired => 4

syntax Int ::= "#ESM.sum" "[" Int "]" [function]
rule #ESM.sum[A] => #hashedLocation("Solidity", 5, A)

syntax Int ::= "#ESM.Sum" [function]
rule #ESM.Sum => 6
```

DSToken storage:

```k
syntax Int ::= "#DSToken.balances" "[" Int "]" [function]
rule #DSToken.balances[A] => #hashedLocation("Solidity", 1, A)

syntax Int ::= "#DSToken.approvals" "[" Int "]" "[" Int "]" [function]
rule #DSToken.approvals[A][B] => #hashedLocation("Solidity", 2, A B)

syntax Int ::= "#DSToken.owner_stopped" [function]
rule #DSToken.owner_stopped => 4
```
