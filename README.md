# rester
An opinionated framework for creating simple and effective RESTful interfaces between
application services.

## Interface

### Client-side
```ruby
PaymentService = Rester.connect("http://url-to-service.com/v1")
PaymentService.cards("card_token").get
# => GET http://url-to-service.com/v1/cards/card_token
# <= { { "last_four": "1111", ... } }

PaymentService.cards!(number: "4111111111111111", exp: '07/20')
# => POST http://url-to-service.com/v1/cards
#    data: number=4111111111111111&exp=07/20

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
    end
  end
end
```
