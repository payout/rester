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
    class Cards < Rester::Object
      class << self
        def search(params)
          # Search for the card.
        end

        def create(params)
          # Create the card.
        end
      end

      ##
      # Instance methods have an `id` variable available which contains the
      # identifier for the designated model.

      def get
        # Lookup card based on id.
      end

      def update(params={})
        # Update the card.
      end

      def delete
        # Delete the card.
      end
      
      ##
      # Additional methods can be defined as well. Ending with a bang
      # will create a POST endpoint, otherwise it'll create a GET endpoint.
      #
      # In both cases these additional methods will receive a hash of values.
      def credit!(params)
        # Send money to the card.
      end
    end
  end
end
```
