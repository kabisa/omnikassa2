describe Omnikassa2 do
  describe 'announce order' do
    before(:each) do
      # Reset the AccessTokenProvider singleton between tests
      Omnikassa2::AccessTokenProvider.class_variable_set(:@@instance, nil)

      Omnikassa2.config(
        ConfigurationFactory.create(
          signing_key: 'bXlTMWduaW5nSzN5',
          base_url: 'https://www.example.org/sandbox'
        )
      )
    end

    let(:merchant_order) do
      MerchantOrderFactory.create(
        merchant_order_id: 'order123',
        amount: Omnikassa2::Money.new(amount: 4999, currency: 'EUR'),
        merchant_return_url: 'http://www.example.org'
      )
    end

    context 'when API returns 500 with HTML error page' do
      before do
        # Stub the refresh endpoint to return a valid access token
        WebMock.stub_request(:get, "https://www.example.org/sandbox/gatekeeper/refresh")
          .to_return(
            status: 200,
            body: {
              token: 'myAccEssT0ken',
              validUntil: "2099-12-31T23:59:59.999+0000",
              durationInMillis: 28800000
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the order endpoint to return 500 with HTML error page
        WebMock.stub_request(:post, "https://www.example.org/sandbox/order/server/api/order")
          .to_return(
            status: 500,
            body: '<HTML><HEAD><TITLE>Internal Server Error</TITLE></HEAD><BODY>Something went wrong</BODY></HTML>',
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'raises HttpError instead of JSON::ParserError' do
        expect {
          Omnikassa2.announce_order(merchant_order)
        }.to raise_error(Omnikassa2::HttpError, /500.*Internal Server Error/m)
      end

      it 'includes the HTML body in the error message' do
        expect {
          Omnikassa2.announce_order(merchant_order)
        }.to raise_error(Omnikassa2::HttpError, /Something went wrong/)
      end
    end

    context 'when API returns 200 with empty body' do
      before do
        WebMock.stub_request(:get, "https://www.example.org/sandbox/gatekeeper/refresh")
          .to_return(
            status: 200,
            body: {
              token: 'myAccEssT0ken',
              validUntil: "2099-12-31T23:59:59.999+0000",
              durationInMillis: 28800000
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        WebMock.stub_request(:post, "https://www.example.org/sandbox/order/server/api/order")
          .to_return(status: 200, body: '')
      end

      it 'raises HttpError' do
        expect {
          Omnikassa2.announce_order(merchant_order)
        }.to raise_error(Omnikassa2::HttpError, /Body: empty/)
      end
    end

    context 'when API returns 200 with invalid JSON' do
      before do
        WebMock.stub_request(:get, "https://www.example.org/sandbox/gatekeeper/refresh")
          .to_return(
            status: 200,
            body: {
              token: 'myAccEssT0ken',
              validUntil: "2099-12-31T23:59:59.999+0000",
              durationInMillis: 28800000
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        WebMock.stub_request(:post, "https://www.example.org/sandbox/order/server/api/order")
          .to_return(status: 200, body: 'not valid json {')
      end

      it 'raises HttpError' do
        expect {
          Omnikassa2.announce_order(merchant_order)
        }.to raise_error(Omnikassa2::HttpError, /not valid json/)
      end
    end
  end

  describe 'status pull' do
    before(:each) do
      Timecop.freeze Time.parse('2016-11-24T17:30:00.000+0000')
    end

    context 'with expiring notification' do
      let(:expiring_notification) do
        NotificationFactory.create(
          expiry: Time.parse('2015-07-12T16:25:00.000+0000')
        )
      end

      it 'triggers error' do
        expect do
          Omnikassa2.status_pull(expiring_notification)
        end.to raise_error(Omnikassa2::ExpiringNotificationError)
      end
    end

    context 'with notification without valid signature' do
      let(:notification_with_invalid_signature) do
        NotificationFactory.create(
          signature: 'invalidSignature'
        )
      end

      it 'triggers error' do
        expect do
          Omnikassa2.status_pull(notification_with_invalid_signature)
        end.to raise_error(Omnikassa2::InvalidSignatureError)
      end
    end
  end
end
