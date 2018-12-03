require 'omnikassa2/requests/order_announce_request'
require 'time'

describe Omnikassa2::OrderAnnounceRequest do
  before(:each) do
    Omnikassa2.config(
      ConfigurationFactory.create(
        base_url: 'https://www.example.com/sandbox'
      )
    )

    WebMock.stub_request(:post, "https://www.example.com/sandbox/order/server/api/order")
      .to_return(
        body: {
          signature: 's1gnaTuRe',
          redirectUrl:  "https://www.example.com/pay?token=S0meT0ken&?lang=nl"
        }.to_json
      )
  end

  let(:order_announcement) do
    OrderAnnouncementFactory.create(
      merchant_order_id: 'myOrderId123',
      amount: Omnikassa2::MoneyAmount.new(
        amount: 240,
        currency: 'EUR'
      ),
      merchant_return_url: 'http://www.example.org/order-completed'
    )
  end

  let(:order_announce_request) do
    Omnikassa2::OrderAnnounceRequest.new(
      order_announcement,
      access_token: 'myAcCEssT0k3n'
    )
  end

  context 'when sent' do
    it 'only invokes one requests' do
      order_announce_request.send
      assert_requested :any, //, times: 1
    end

    it 'uses correct HTTP method' do
      order_announce_request.send
      assert_requested :post, //
    end

    it 'uses correct URL' do
      order_announce_request.send
      assert_requested :any, 'https://www.example.com/sandbox/order/server/api/order'
    end

    it 'sets header: \'Content-Type: application/json\'' do
      order_announce_request.send
      assert_requested :any, //, headers: {'Content-Type' => 'application/json'}
    end

    it 'sets header: \'Authorization: Bearer <access-token>\'' do
      order_announce_request.send
      assert_requested :any, //, headers: {'Authorization' => 'Bearer myAcCEssT0k3n'}
    end

    describe 'request body' do
      it 'has timestamp' do
        Timecop.freeze Time.parse('2017-02-06T08:32:51.759+01:00')
        order_announce_request.send

        assert_requested(:any, //) do |request|
          JSON.parse(request.body)['timestamp'] == '2017-02-06T08:32:51.759+01:00'
        end
      end

      it 'has merchantOrderId' do
        order_announce_request.send

        assert_requested(:any, //) do |request|
          JSON.parse(request.body)['merchantOrderId'] == 'myOrderId123'
        end
      end

      it 'has amount.amount' do
        order_announce_request.send

        assert_requested(:any, //) do |request|
          JSON.parse(request.body)['amount']['amount'] == '240'
        end
      end

      it 'has amount.currency' do
        order_announce_request.send

        assert_requested(:any, //) do |request|
          JSON.parse(request.body)['amount']['currency'] == 'EUR'
        end
      end

      it 'has merchantReturnURL' do
        order_announce_request.send

        assert_requested(:any, //) do |request|
          JSON.parse(request.body)['merchantReturnURL'] == 'http://www.example.org/order-completed'
        end
      end

      it 'has a signature' do
        order_announce_request.send

        assert_requested(:any, //) do |request|
          body = JSON.parse(request.body)
          body.key?('signature') && !body['signature'].empty?
        end
      end
    end
  end
end
