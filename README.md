[![Gem Version](https://badge.fury.io/rb/rester.svg)](http://badge.fury.io/rb/rester) [![Build Status](https://travis-ci.org/payout/rester.svg?branch=master)](https://travis-ci.org/payout/rester) [![Code Climate](https://codeclimate.com/github/payout/rester/badges/gpa.svg)](https://codeclimate.com/github/payout/rester) [![Test Coverage](https://codeclimate.com/github/payout/rester/badges/coverage.svg)](https://codeclimate.com/github/payout/rester/coverage)

# Rester
An opinionated framework for creating simple and effective RESTful interfaces between application services. The intended use-case is inter-service communication, not to provide a publically accessible API. There are better libraries for doing that (e.g., grape).

On the service (i.e., producer) side, Rester works by defining resources (e.g., 'users', 'comments', 'orders', etc.) which can be accessed via a RESTful API (e.g., `GET /v1/users/:user_id`). Resources can also be mounted within each other (e.g., `GET /v1/users/:user_id/comments`).  Rester doesn't allow you to define abitrary API paths (e.g., `/v1/users/my/arbitrary/path`) in order to enforce simplicity and predictability. This also simplifies integration on the client (i.e., consumer) side since interfacing with a service's resources always follows a predictable pattern.

Where possible, we've tried to avoid the use of custom DSL and rely on standard Ruby syntax to define resources and methods.

## Installation
```ruby
gem install rester
```

## Basic Usage

### Client-side
For non-Rails applications and non-Rester services, a Rester middleware will be
needed for creating a Correlation ID for outgoing requests. Add the middleware
in `config.ru`:
```ruby
require 'rester'
use Rester::Client::Middleware::RequestHandler
```
This is done automatically for Rails applications

```ruby
# Service name defaults to the Rails application name or the name of a defined
# Rester Service. If neither is available, a custom name must be set. Otherwise,
# this field is optional.
Rester.service_name = "My Customer Service Name"

# Connect to the external service
PaymentService = Rester.connect("http://url-to-service.com", version: 1)

##
# Retrieve individual records:
PaymentService.cards("card_token").get
# => GET http://url-to-service.com/v1/cards/card_token
# <= { { "last_four": "1111", ... } }

##
# Create records
PaymentService.cards!(number: "4111111111111111", exp: '07/20', customer_id: 'customer_id')
# => POST http://url-to-service.com/v1/cards
#    body: number=4111111111111111&exp=07/20&customer_id=customer_id

##
# Search for records:
PaymentService.cards(customer_id: 'customer_id')
# => GET http://url-to-service.com/v1/cards?customer_id=customer_id

##
# Mount resources in other resources.
PaymentService.cards("card_token").credits!(amount_cents: 10)
# => POST http://url-to-service.com/v1/cards/card_token/credits
#    body: amount_cents=10
```

### Service-side
```ruby
class PaymentService < Rester::Service
  module V1
    class Card < Rester::Service::Resource
      id :token
      mount Credit

      # Set of params that can be used for multiple endpoints
      shared_params = Params.new {
        String :token
        Integer :id
      }

      params do
        String :str
        Integer :something
      end
      def search(params)
        # Search for the card.
      end

      # Strict params which only allow the params specified
      params strict: true do
        String :some_field
      end
      def create(params)
        # Create the card.
      end

      ##
      # GET /v1/cards/:token
      # Using the shared params
      params do
        use shared_params
      end
      def get(params)
        # Lookup card based on params[:card_token].
      end

      ##
      # PUT /v1/cards/:token
      # Using the shared params and another param
      params do
        use shared_params
        Integer :an_additional_field
      end
      def update(params={})
        # Update the card.
      end

      ##
      # DELETE /v1/cards/:token
      def delete
        # Delete the card.
      end
    end

    class Credit < Rester::Service::Resource
      ##
      # Can be called directly via: POST /v1/credits
      # Or can be called via POST /v1/cards/token/credits
      # In the later case, a `card_token` parameter will
      # automatically be passed to it.
      def create(params)
      end

      ##
      # GET /v1/credits/token
      #
      # Only class methods are available via a mount.
      def get
      end
    end
  end
end
```

## Advanced Client Usage
### Timeouts
By default the Rester client has a timeout of 10 seconds. This can be configured when connecting.

For example:
```ruby
# Set a timeout of 30 seconds.
MyService = Rester.connect('http://example.com', version: 1, timeout: 30)
```

If the timeout is exceeded, a `Rester::Errors::TimeoutError` is raised.

### CircuitBreaker
The Rester client has a built circuit breaker. It has two options: `error_threshold` and `retry_period`. The former is an integer representing the number of exceptions that can be raised while processing the request before breaking the circuit and the latter is the amount of time in seconds (may be specified as a float) to wait before retrying. The defaults are `3` and `1.0`, respectively.

For example:
```ruby
MyService = Rester.connect('http://example.com', version: 1, error_threshold: 5, retry_period: 2.0)
```

In this example, the circuit will open if 5 consecutive errors occur (e.g., timeout errors or errors raised on the server). Once the circuit is open, any request made to the client will raise a `Rester::Errors::CircuitOpenError` without actually making the request. This reduces the load on recovering downstream systems and helps prevent timeouts from propagating (i.e., timeouts in one service causing timeouts in another service). Once the `retry_period` of 2 seconds has passed, the next request will be allowed through. If it succeeds, the circuit will close again and all requests will be permitted through again. If it fails, the circuit will remain open.

By default, the circuit breaker is enabled for all environments except `test`. If you wish to enable or disable the circuit breaker manually, add the following as a param when you are connecting to your service via Rester:

For example:
```ruby
MyService = Rester.connect('http://example.com', circuit_breaker_enabled: false)
```

## Service Params
```ruby
class ExampleService < Rester::Service
  module V1
    class MyResource < Rester::Service::Resource
      # By default all params blocks are strict.
      params strict: true do
        # Any method that can be called on the object can be used to validate
        # it. Here the `#between?` method will be called with the args (1, 10).
        # As long as the method returns truthy, the validation will pass.
        Integer :integer, between?: [1,10]

        # Here's another example (not sure how this would be useful though!)
        Float :float, zero?: []

        # Boolean has special handling since Ruby doesn't have a Boolean object.
        Boolean :bool

        # Any other data type can be used, too! But it needs to provide a
        # ::parse class method, like DateTime.
        DateTime :date

        # Use the `match` validator to validate the value sent to the server
        # *before* it is parsed (note: this is a bad date regex!).
        DateTime :date, match: /\A\d{4}-\d{2}-\d{2}\z/

        # Use the `within` matcher to verify that the object is within an
        # expected set.
        Symbol :symbol, within: [:one, :two, :three]

        # `within` will also work with anything that responds to `include?`,
        # a range for example.
        Float :another_float, within: (0..1)

        # Nested hashes are also supported.
        Hash :hash, strict: false do
          # Another params block!
        end

        # Arrays are supported, too. Here validators apply to each element of
        # the array individually.
        Array :array, type: Float, within: (0..1)

        # Arrays of hashes work, too.
        #
        # CAUTION: Each hash in the array must contain the same keys in order to
        # ensure they are properly decoded on the service-side. To be on the
        # safe side, make nested hashes like this strict and all their params
        # required.  To be on the safer side, don't use this :)
        Array :array_of_hashes, type: Hash, strict: true do
          # Another params block!
        end
      end
      def get
      end
    end
  end
end
```

## Contract Testing

### Client-side (consumer) Stub Testing

The client is responsible for writing contracts for producer service requests that are in used in their application.

1. Create a stubfile with the following format to stub the requests you expect to make in your application:
2. Create RSpec unit tests for your application.
3. Use `YourService.with_context` in your RSpec tests to point to the correct stub example you will need to use for your testing (a sample RSpec test is below)
4. When testing, to connect to the Rester service that was stubbed, pass in the path to your Stubfile for the 'SERVICE_URL' like below:
5. Rester will retrieve all responses made to your service from the Stubfile. If any requests in your application are made that don't exist in your Stubfile, then an error will be raised.


#### Stub Example:
```yml
version: 1
consumer: some_client
producer: some_service

/v1/cards:
  POST:
    With valid card details:
      request:
        card_number: "4111111111111111"
        exp_month: "08"
        exp_year: "2017"
      response:
        token: "CTABCDEFG"
        exp_month: "08"
        exp_year: "2017"
        status: "ready"
    With expired card:
      request:
        card_number: "411111111"
        exp_month: "01"
        exp_year: "2000"
      response[successful=false]:
        error: "validation_error"
        message: "card expired"

```

#### Spec Example:
```ruby
ENV['PAYMENT_SERVICE_URL'] = '/path/to/stub/file.yml'
PaymentService = Rester.connect(ENV['PAYMENT_SERVICE_URL'] , version: 1)

...
# spec/api/do_something_spec.rb
describe '/v1/do_something' do
  context "with something" do
    around { |ex|
      CoreService.with_context("With vaild card details") { ex.run }
    }

    let(:token) { 'CTabcdef' }

    it 'should do something' do
      lookup_card(token)
        # CoreService.cards('CTabcdef').get

      process_transaction
        # CoreService.cards('CTabcdef').credits!(amount_cents: 100)
    end

  end
end
```

### Service-side (producer) Stub Testing

The Service providers are responsible for verifying that the stubs created by their clients are, in fact, accurate.

#### Stub Example (written by client):
```yml
/v1/cards:
  POST:
    With valid card details:
      request:
        card_number: "4111111111111111"
        exp_month: "08"
        exp_year: "2017"
      response:
        token: "CTABCDEFG"
        exp_month: "08"
        exp_year: "2017"
        status: "ready"
    With invalid card details:
      request:
        card_number: "4111111111111111"
        exp_month: "08"
        exp_year: "2017"
      response[successful=false]:
        error: card_declined
```

#### Service RSpec Test Example:

You need to `require 'rester/rspec'` in your `spec_helper.rb` file.

```ruby
RSpec.describe PaymentService, rester: "/path/to/stub/file.yml" do
  describe '/v1/cards' do
    context 'POST' do
      context 'With valid card details' do
        before {
          # Perform any operations needed set the test up for success.
        }

        # The include_stub_response matcher will compare the response of your service with
        # the response defined in the stub. For fields generated non-deterministically within
        # your endpoint, the format of the field in the stub and in the service's response
        # can be validated with a regex.
        it 'should satisfy stub' do
          is_expected.to include_stub_response(
            created_at: /\A2[0-9]{3}-[01][0-9]-[0-3][0-9]T[012][0-9]:[0-5][0-9]:[0-5][0-9]\+00:00\z/
          )
        end
      end
    end
  end
end
```
