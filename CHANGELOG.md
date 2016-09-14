# Changelog

## 0.5.9
 * [[#106](https://github.com/payout/rester/issues/106)] - Updating endpoint path regex to support for dashes (`-`) in identifiers (e.g., `/v1/resources/id-1234`).

## 0.5.8
 * [[#104](https://github.com/payout/rester/issues/104)] - Logging timeout errors on client side.

## 0.5.7
 * [[#98](https://github.com/payout/rester/issues/98)] - Making `Client::Adapter.connect` error message clearer.
 * [[#100](https://github.com/payout/rester/issues/100)] - Making Rails detection more robust.

## 0.5.6
 * [[#95](https://github.com/payout/rester/issues/95)] - Adding support for dynamic (defined by regex) parameter names.

## 0.5.5
 * [[#93](https://github.com/payout/rester/issues/93)] - Improving `include_stub_response` rspec matcher to support regex validation. Now when testing creation endpoints, the format of the stub and the response can be verified, instead of requiring a direct match (e.g., with a `created_at` field).

## 0.5.4
 * [[#90](https://github.com/payout/rester/issues/90)] - Automatically installing Client::Middleware::RequestHandler on first call to `Rester.connect`. This is useful for Rails apps.

## 0.5.3
 * [[#88](https://github.com/payout/rester/issues/88)] - Fixing bug with how request information is managed.

## 0.5.2
 * [[#24](https://github.com/payout/rester/issues/24)][[#86](https://github.com/payout/rester/issues/86)] - Automatically generating, managing and logging correlation IDs for requests. This allows correlating multiple rester requests/responses between multiple rester services.
 * [[#80](https://github.com/payout/rester/issues/80)] - Disabled circuit breaker when using StubAdapter. This improves testing.
 * [[#84](https://github.com/payout/rester/issues/84)] - Now reports clearer error messages when a path/verb/context is referenced that's not defined in the stub file.

## 0.5.1
 * [[#32](https://github.com/payout/rester/issues/32)] - Added NewRelic middleware to provide better New Relic integration.
 * [[#72](https://github.com/payout/rester/issues/72)] - Now when producer side tests are missing, a pending test is added. Previously, an unclear error was given.
 * [[#77](https://github.com/payout/rester/issues/77)] - Clearer error messages when an array or hash is expected for a param but a non-array/hash is sent.

## 0.5.0
 * [[#11](https://github.com/payout/rester/issues/11)] - Added support for Array and Hash params. Also includes better handling of nil params.
 * [[#60](https://github.com/payout/rester/issues/60)] - Improved stub test errors.

## 0.4.2
 * [[#22](https://github.com/payout/rester/issues/22)] - Added circuit breaker and timeouts.
 * [[#37](https://github.com/payout/rester/issues/37)] - Pre-parse matching of parameters.
 * [[#61](https://github.com/payout/rester/issues/61)][[#64](https://github.com/payout/rester/issues/64)] - Improved support for testing.

## 0.4.1
 * [#58](https://github.com/payout/rester/issues/58) - Added respond_to_missing? to Response. Improves usability of response objects.

## 0.4.0
**Summary**:
 * Params now strict by default.
 * Improving StubFile parsing.
 * Adding support for response tags (e.g., "response[successful=false]")
 * The `Client::Response` object is no longer a hash itself.

See issues here: https://github.com/payout/rester/issues?q=is%3Aissue+milestone%3A0.4.0+is%3Aclosed

## 0.3.3
Producer-side testing improvements.

See full list: https://github.com/payout/rester/issues?q=milestone%3A0.3.3+is%3Aclosed

## 0.3.2
 * [#45](https://github.com/payout/rester/issues/45) - Bug fix to stub request matching.

## 0.3.1
 * [#43](https://github.com/payout/rester/issues/43) - Improved StubAdapter's context handling.

## 0.3.0

Significant overall improvements.

See full list of changes:
https://github.com/payout/rester/issues?q=is%3Aissue+milestone%3A0.3.0+is%3Aclosed

**Summary:**
 * `Service::Object` renamed to `Service::Resource`
 * Per resource method `params` blocks (rather than a service global block of params).
 * The `create` and `search` resource methods have become instance methods (previously they were class methods). This was to enable the above and to make the interface more uniform.
 * Resource ID now passed as a parameter (e.g., `user_id`) instead of being accessed via a helper method (e.g., `id`).
 * Standardized how errors should be handled. Responses have a `successful?` method to determine if the request was successful, rather than raising an exception for all unsuccessful responses. Now only server errors or Rester related errors raise exceptions.  All application layer errors (e.g., validation errors) must be handled by application logic.  If the request was not successful, the body of the response will contain error details.

## 0.2.4
 * [#7](https://github.com/payout/rester/issues/7) - Validation errors are now treated as request errors (http 400) instead of server errors (http 500).

## 0.2.3
 * Fixed bug when putting data to an endpoint with the LocalAdapter. Because the content type wasn't set, Rack wasn't parsing the body. This preventing you from being able to pass params to an #update method.

## 0.2.2
 * Bug fix to the interface between LocalAdapter and Client. LocalAdapter wasn't returning the body in a format that the client could handle.

## 0.2.1
 * Fixing bug when connecting with a LocalAdapter. The version wasn't being specified!

## 0.2.0
 * [#2](https://github.com/payout/rester/issues/2) - Adding params DSL to add validation.
 * [#3](https://github.com/payout/rester/issues/3) - Adding support for nil and bool types to be sent to the service from the client.
 * [#4](https://github.com/payout/rester/issues/4) - Adding LocalAdapter to simplify testing.

## 0.1.1
 * Initial proof of concept release
