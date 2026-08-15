# `delete_account_repo_test.dart`

Covers `DeleteAccountRepo`, the client half of `DELETE /api/users/me`.

## What it covers

The repo's only real job is building the confirmation body, and the thing worth
pinning is that it sends **one** credential, never both. An account with a
password confirms with the password; a Google account, which has none, types its
own username back instead. A stray `confirmUsername: null` riding along with a
password would read on the server as an OAuth confirmation attempt against an
account that has a password, so the tests assert the absent key, not just the
present one.

The failure tests cover the two shapes a caller cares about: a 401 (the server
rejecting the password or username) and a transport failure.

## Mocks

`ApiService` via `@GenerateMocks`, same as the login repo tests.

## Gotcha worth keeping

"surfaces a rejected confirmation as a failure with its status" asserts the 401
survives `ApiErrorHandler.handle`. It did not, at first: `ApiErrorModel.fromJson`
reads `statusCode` out of the response *body*, and a handler returning a bare
`{"message": …}` produced a model with a null status. `DeleteAccountCubit` keys
its "wrong password" message off that 401, so the whole distinction between a
typo and a server error was riding on the API happening to echo the status.
`_handleError` now falls back to the status the response arrived with.
