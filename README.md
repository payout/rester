# restercom
A RESTful replacement for Intercom.

## Interface

### Client-side
```ruby
MyService = Restercom.connect("http://url-to-service.com")
MyService.list_transactions("card_token", page: 1, page_size: 10)
# => GET http://url-to-service.com/transactions/card_token?page=1&page_size=10
# <= { "transactions": [{ amount_cents: 100, state: "cleared", time: 1234567890 }, ...] }
```

### Service-side
```ruby
class MyService < Restercom::Service
  def transactions(card_token, params={})
    {
      page = params[:page].to_i
      page_size = params[:page_size].to_i
      
      transactions: [
        { amount_cents: 100, state: "cleared", time: 1234567890 },
        { amount_cents: 200, state: "failed", time: 1234567891 }
      ]
    }
  end
end
```
