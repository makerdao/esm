ESM storage:

```k
syntax Int ::= "#ESM.gem" [function]
rule #ESM.gem => 0

syntax Int ::= "#ESM.end" [function]
rule #ESM.gem => 1

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

syntax Int ::= "#DSToken.approvals" "[" Int "][" Int "]" [function]
rule #DSToken.approvals[A][B] => #hashedLocation("Solidity", 2, A B)

syntax Int ::= "#DSToken.owner_stopped" [function]
rule #DSToken.owner_stopped => 4
```

End storage:

```
syntax Int ::= "#End.wards" "[" Int "]" [function]
rule #End.wards[A] => #hashedLocation("Solidity", 0, A)

syntax Int ::= "#End.vat" [function]
rule #End.vat => 1

syntax Int ::= "#End.cat" [function]
rule #End.cat => 2

syntax Int ::= "#End.vow" [function]
rule #End.vow => 3

syntax Int ::= "#End.spot" [function]
rule #End.spot => 4

syntax Int ::= "#End.live" [function]
rule #End.live => 5

syntax Int ::= "#End.when" [function]
rule #End.when => 6

syntax Int ::= "#End.wait" [function]
rule #End.wait => 7

syntax Int ::= "#End.debt" [function]
rule #End.debt => 8

syntax Int ::= "#End.tag" "[" Int "]" [function]
rule #End.tag[Ilk] => #hashedLocation("Solidity", 9, Ilk)

syntax Int ::= "#End.gap" "[" Int "]" [function]
rule #End.gap[Ilk] => #hashedLocation("Solidity", 10, Ilk)

syntax Int ::= "#End.Art" "[" Int "]" [function]
rule #End.Art[Ilk] => #hashedLocation("Solidity", 11, Ilk)

syntax Int ::= "#End.fix" "[" Int "]" [function]
rule #End.fix[Ilk] => #hashedLocation("Solidity", 12, Ilk)

syntax Int ::= "#End.bag" "[" Int "]" [function]
rule #End.bag[Usr] => #hashedLocation("Solidity", 13, Usr)

syntax Int ::= "#End.out" "[" Int "][" Int "]" [function]
rule #End.out[Ilk][Usr] => #hashedLocation("Solidity", 14, Ilk Usr)
```
