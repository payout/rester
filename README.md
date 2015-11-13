[![Gem Version](https://badge.fury.io/rb/rester.svg)](http://badge.fury.io/rb/rester) [![Build Status](https://semaphoreci.com/api/v1/projects/a4233ca0-25dd-49ff-8bde-4ed5218d8f60/559761/shields_badge.svg)](https://semaphoreci.com/payout/rester) [![Code Climate](https://codeclimate.com/github/payout/rester/badges/gpa.svg)](https://codeclimate.com/github/payout/rester) [![Test Coverage](https://codeclimate.com/github/payout/rester/badges/coverage.svg)](https://codeclimate.com/github/payout/rester/coverage)

# Rester
An opinionated framework for creating simple and effective RESTful interfaces between application services. The goal is to create a way to rapidly develop new services without needing to package SDKs into gems or interface directly with the web interface.

The intended use-case for Rester is inter-service communication, not to provide a publically accessible API. There are better libraries for doing that (e.g., grape). Rester is forces a particular API design and development pattern that enforces simplicity and predictability.

## Installation
```ruby
gem install rester
```

## Interface

### Client-side
```ruby
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
#    data: number=4111111111111111&exp=07/20

##
# Search for records:
PaymentService.cards(customer_id: 'customer_id')
# => GET http://url-to-service.com/v1/cards?customer_id=customer_id

##
# Mount resources in other resources.
PaymentService.cards("card_token").credits!(amount_cents: 10)
# => POST http://url-to-service.com/v1/cards/card_token/credits
#    data: amount_cents=10
```

### Service-side
```ruby
class PaymentService < Rester::Service
  module V1
    class Card < Rester::Resource
      id :token
      mount Credit

      params do
        String :str
        Integer :something
      end

      def search(params)
        # Search for the card.
      end

      def create(params)
        # Create the card.
      end

      ##
      # GET /v1/cards/:token
      def get(params)
        # Lookup card based on params[:card_token].
      end

      ##
      # PUT /v1/cards/:token
      def update(params={})
        # Update the card.
      end

      ##
      # DELETE /v1/cards/:token
      def delete
        # Delete the card.
      end
    end

    class Credit < Rester::Resource
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

## Contract Testing

### Client-side Stub Testing

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
        code: 200
        body:
          token: "CTABCDEFG"
          exp_month: "08"
          exp_year: "2017"
          status: "ready"
    With expired card:
      request:
        card_number: "411111111"
        exp_month: "01"
        exp_year: "2000"
      response:
        code: 400
        body:
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


### Service-side Stub Testing

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
        code: 200
        body:
          token: "CTABCDEFG"
          exp_month: "08"
          exp_year: "2017"
          status: "ready"
```

#### Service RSpec Test Example:

You need to `require 'rester/rspec' in your `spec_helper.rb` file.

```ruby
RSpec.describe PaymentService, rester: "/path/to/stub/file.yml" do
  describe '/v1/cards' do
    context 'POST' do
      context 'With valid card details' do
        before {
          # Perform any operations needed set the test up for success.
        }

        # The `subject` and `stub_response` variables are created by Rester so the
        # line below is all that is needed to verify that the Service is providing
        # what the Stubfile expects for this specific request
        it { is_expected.to include stub_response }
      end
    end
  end
end
```
