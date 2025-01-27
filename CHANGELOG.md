# Revision history for `maestro-sdk`

## [1.3.0](https://github.com/maestro-org/haskell-sdk/compare/v1.2.0..v1.3.0) -- 2023-11-27

* Removed deprecated `/datum` endpoint in favour of `/datums`, [#42](https://github.com/maestro-org/haskell-sdk/pull/42).
* Support for endpoint to query UTxOs at a single address, [#42](https://github.com/maestro-org/haskell-sdk/pull/42).

## [1.2.0](https://github.com/maestro-org/haskell-sdk/compare/v1.1.0..v1.2.0) -- 2023-10-18

* Incorporating updated response when submitting the transaction, [#41](https://github.com/maestro-org/haskell-sdk/pull/41).

## [1.1.0](https://github.com/maestro-org/haskell-sdk/compare/v1.0.0..v1.1.0) -- 2023-09-23

* Support of v0 family of endpoints have been dropped, [#33](https://github.com/maestro-org/haskell-sdk/pull/33).
* Support of backoff, to automatically handle rate limit errors by allowing clients to use exponential backoff with maximum delay threshold, [#40](https://github.com/maestro-org/haskell-sdk/pull/40).
* Support of Preview network is added, [#37](https://github.com/maestro-org/haskell-sdk/pull/37).
