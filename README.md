# Omnikassa2

This Gem provides the Ruby integration for the new Omnikassa 2.0 JSON API from the
Rabobank. The documentation for this API is currently here:
[Rabobank.nl](https://www.rabobank.nl/images/handleiding-merchant-shop_29920545.pdf)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omnikassa2'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omnikassa2


## Configuration
You can find your `refresh_token` and `signing_key` in Omnikassa's dashboard. The `base_url` corresponds with the base_url of the Omnikassa2 API. You can use `:sandbox` or `:production` as well.

```ruby
Omnikassa2.config(
  refresh_token: 'my_refresh_token',
  signing_key: 'my_signing_key',
  base_url: :sandbox # Shortcut for 'https://betalen.rabobank.nl/omnikassa-api-sandbox'
)
```

For [Status Pull](#status-pull), it is required to configure a webhook as well (see official documentation).

## Announce order
```ruby
response = Omnikassa2.announce_order(
  Omnikassa2::MerchantOrder.new(
    merchant_order_id: 'order123',
    amount: Money.new(
      amount: 4999,
      currency: 'EUR'
    ),
    merchant_return_url: 'https://www.example.org/my-webshop'
  )
)

redirect_url = response.redirect_url

# Send client to 'redirect_url'
```

## Status pull
Performing a status pull is only possible when notified by Omnikassa through a configured webhook in the dashboard.

```ruby
# pseudocode
class MyOmnikassaWebhookController
  def post(request)
    # Create notification object
    notification = Omnikassa2::Notification.from_json request.body

    # Use notification object to retrieve statusses
    Omnikassa2.status_pull(notification) do |order_status|
      # Do something
      puts "Order: #{ order_status.merchant_order_id}"
      puts "Paid amount: #{ order_status.paid_amount.amount }"
    end
  end
end
```

## Development

Feel free to contact us if you need help implementing this Gem in your
application. Also let us know if you need additional features.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/omnikassa2.
