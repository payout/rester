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
    class Cards

    end
  end
  def list(card_token, params={})
    {
      page = params[:page].to_i
      page_size = params[:page_size].to_i

      payment: [
        { amount_cents: 100, state: "cleared", time: 1234567890 },
        { amount_cents: 200, state: "failed", time: 1234567891 }
      ]
    }
  end

  # Methods with a bang signify a POST.
  def create!(card_token, params={})
    # Create a payment.
  end
end
```
