# restercom
A RESTful replacement for Intercom.

## Interface

### Client-side
```ruby
PaymentService = Restercom.connect("http://url-to-service.com")
PaymentService.list("card_token", page: 1, page_size: 10)
# => GET http://url-to-service.com/list/card_token?page=1&page_size=10
# <= { "payments": [{ amount_cents: 100, state: "cleared", time: 1234567890 }, ...] }

PaymentService.create!(card_token, amount_cents: 10)
# => POST http://url-to-service.com/create/card_token
#    data: amount_cents=10
```

### Service-side
```ruby
class PaymentService < Restercom::Service
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
