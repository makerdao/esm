# ESM

Emergency Shutdown Module

## Invariants

* `fire` can be triggered by anyone
* `fire` can be triggered iff the ESM's balance is >= the `cap`
* `free` and `burn` are `auth`ed
* state transitions are only allowed in the `START` and `FIRED` states
* cycles are not allowed, i.e. the ESM is single-use
* `join` can be called only in the `START` state
* `join` can be called even after the `cap` has been reached
* `exit` can be called only in the `FREED` state
* the `cap` only accounts for `gem`s transferred via `join`, but `burn` burns
  the whole balance of the ESM
  * this makes the embargo on `join` meaningful

## Allowed state transitions

* `start` -> `freed`
* `start` -> `burnt`
* `start` -> `fired`

* `fired` -> `freed`
* `fired` -> `burnt`

## Authorization

The ESM is meant to sit behind a DSPause, who's authorized to call its `auth`ed
methods (either by being passed as `ward` in the constructor, or via a
subsequent call to `rely`).

The DSPause would then have the Chief as its `authority`, allowing the `hat` to
plot plans on it.
