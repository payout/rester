[![Gem Version](https://badge.fury.io/rb/rester.svg)](http://badge.fury.io/rb/rester) [![Build Status](https://semaphoreci.com/api/v1/projects/a4233ca0-25dd-49ff-8bde-4ed5218d8f60/559761/shields_badge.svg)](https://semaphoreci.com/payout/rester) [![Code Climate](https://codeclimate.com/github/payout/rester/badges/gpa.svg)](https://codeclimate.com/github/payout/rester) [![Test Coverage](https://codeclimate.com/github/payout/rester/badges/coverage.svg)](https://codeclimate.com/github/payout/rester/coverage)

# Rester
An opinionated framework for creating simple and effective RESTful interfaces between
application services. The goal is to create a way to rapidly develop new services
without needing to package SDKs into gems or interface directly with the web interface.

## Installation
```ruby
gem install rester
```

## Interface

### Client-side
```ruby
PaymentService = Rester.connect("http://url-to-service.com/v1")
PaymentService.cards("card_token").get
# => GET http://url-to-service.com/v1/cards/card_token
# <= { { "last_four": "1111", ... } }

PaymentService.cards!(number: "4111111111111111", exp: '07/20', customer_id: 'customer_id')
# => POST http://url-to-service.com/v1/cards
#    data: number=4111111111111111&exp=07/20

PaymentService.cards(customer_id: 'customer_id')

PaymentService.cards("card_token").credit!(amount_cents: 10)
# => POST http://url-to-service.com/v1/cards/card_token/credit
#    data: amount_cents=10
```

### Service-side
```ruby
class PaymentService < Rester::Service
  module v1
    class Card < Rester::Object
      id :token
      mount Credit
    
      def self.search(params)
        # Search for the card.
      end

      def self.create(params)
        # Create the card.
      end

      ##
      # Instance methods will have a `token` variable available which contains the
      # identifier for the designated model.

      ##
      # GET /v1/cards/:token
      def get
        # Lookup card based on token.
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
    
    class Credit < Rester::Object
      ##
      # Can be called directly via: POST /v1/credits
      # Or can be called via POST /v1/cards/token/credits
      # In the later case, a `card_token` parameter will
      # automatically be passed to it.
      def self.create(params)
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
