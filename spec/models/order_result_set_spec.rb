require 'json'
require 'omnikassa2/models/access_token'
require 'timecop'
require 'time'

describe Omnikassa2::OrderResultSet do
  let(:signature) do
    'c95d401cb42c28cd8754ff85776cb0b58dd0beab88610b6f78408ca906da68c921c6c80fecaed6325f15a2b86cb42a47484394f2ae6632099e5ce272837ae49a'
  end

  let(:json_params) do
    {
      signature: signature,
      moreOrderResultsAvailable: false,
      orderResults: [
        {
          merchantOrderId: 'order123',
          omnikassaOrderId: '1d0a95f4-2589-439b-9562-c50aa19f9caf',
          poiId: '2004',
          orderStatus: 'CANCELLED',
          orderStatusDateTime: '2016-11-25T13:20:03.157+01:00',
          errorCode: '',
          paidAmount: {
            currency: 'EUR',
            amount: '0'
          },
          totalAmount: {
            currency: 'EUR',
            amount: '4999'
          }
        }
      ]
    }
  end

  before(:each) do
    Omnikassa2.config(
      ConfigurationFactory.create(
        signing_key: 'bXlTMWduaW5nSzN5' # Base64.encode64('myS1gningK3y')
      )
    )
  end

  context 'when creating from JSON' do
    subject {
      Omnikassa2::OrderResultSet.from_json(
        JSON.generate(
          json_params
        )
      )
    }

    let(:order) { subject.order_results.first }

    it 'stores signature as string' do
      expect(subject.signature).to eq(signature)
    end

    it 'stores moreOrderResultsAvailable as a boolean' do
      expect(subject.more_order_results_available).to eq(false)
    end

    it 'stores order.merchantOrderId' do
      expect(order.merchant_order_id).to eq('order123')
    end

    it 'stores order.omnikassaOrderId' do
      expect(order.omnikassa_order_id).to eq('1d0a95f4-2589-439b-9562-c50aa19f9caf')
    end

    it 'stores order.poiId' do
      expect(order.poi_id).to eq('2004')
    end

    it 'stores order.orderStatus' do
      expect(order.order_status).to eq('CANCELLED')
    end

    it 'stores order.orderStatusDateTime as Time' do
      expect(order.order_status_date_time).to eq(Time.parse('2016-11-25T13:20:03.157+01:00'))
    end

    it 'stores order.errorCode' do
      expect(order.error_code).to eq('')
    end

    it 'stores order.paidAmount.currency' do
      expect(order.paid_amount.currency).to eq('EUR')
    end

    it 'stores order.paidAmount.amount' do
      expect(order.paid_amount.amount).to eq(0)
    end

    it 'stores order.totalAmount.currency' do
      expect(order.total_amount.currency).to eq('EUR')
    end

    it 'stores order.totalAmount.amount' do
      expect(order.total_amount.amount).to eq(4999)
    end
  end

  describe 'signature_valid?' do
    context 'when signature is valid' do
      subject {
        Omnikassa2::OrderResultSet.from_json(
          JSON.generate(
            json_params
          )
        )
      }

      it 'returns true' do
        expect(subject.valid_signature?).to eq(true)
      end
    end

    context 'when signature is not valid' do
      subject {
        Omnikassa2::OrderResultSet.from_json(
          JSON.generate(
            json_params.merge(
              signature: 'invalidSignature'
            )
          )
        )
      }

      it 'returns false' do
        expect(subject.valid_signature?).to eq(false)
      end
    end
  end
end
