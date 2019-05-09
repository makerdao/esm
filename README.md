# ESM

Emergency Shutdown Module

## Invariants

* `fire` can be triggered by anyone
* `fire` can be triggered iff the ESM's balance is >= the `cap`
* `fire` can only be called once
* state transition functions are `auth`ed
* `spent` means either `FIRED` or `BURNT`
* `join` can be called only in the `BASIC` state and iff `!spent`
  * notably, `join` cannot be called in the `FREED` state, as that would
    contradict the will of governance, i.e. to clear up the ESM
* `join` can be called even after the `cap` has been reached
* `exit` can be called only in the `FREED` state
* once `burn` is called, no further state change is possible
  * to protect the internal balance kept by the ESM, as it's impractical to set
    `gems[address]` to 0 for all possible addresses.
* the `cap` only accounts for `gem`s transferred via `join`, but `burn` burns
  the whole balance of the ESM
  * this makes the embargo on `join` meaningful

## Allowed state transitions

* `basic`
  * `freed`
  * `burnt`
  * `fired`
* `freed`
  * `basic`
  * `freed`
  * `burnt`
  * `fired`
* `burnt`
  * `burnt`
* `fired`
  * `freed`
  * `burnt`
