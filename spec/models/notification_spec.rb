require 'json'
require 'omnikassa2/models/access_token'
require 'timecop'
require 'time'

describe Omnikassa2::Notification do
  before(:each) do
    Omnikassa2.config(
      ConfigurationFactory.create(
        signing_key: 'bXlTMWduaW5nSzN5' # Base64.encode64('myS1gningK3y')
      )
    )
  end

  let(:authentication_token) do
    'eyJraWQiOiJOTyIsImFsZyI6IkVTMjU2In0.eyJubyMiOjEyMywibWtpZCI6NSwibm8kIjoibWVyY2hhbnQub3JkZXIuc3RhdHVzLmNoYW5nZWQiLCJjaWQiOiJhYmNkLTEyMzQiLCJleHAiOjE0ODg0NjQ1MDN9.MEUCIHtPFoKmXAc7JNQjj0U5rWpl0zR9RsQvgj_nckHBngHAiEAmbtgrxaiy4cS3BTHd0DJ8md3Rn7V13Nv35m5DurY1wI'
  end

  let(:signature) do
    'f3aef18aedb04b9f65c6036414ee8c23762db3d245b5bd48519a81174cd59be8dd8ccd2a269fdbc8ed34f584df2c6b41a3a8944f30d914b82db03e18b51274ef'
  end

  let(:base_params) do
    {
      authentication: authentication_token,
      expiry: Time.parse('2016-11-25T09:53:46.765+01:00'),
      event_name: 'merchant.order.status.changed',
      poi_id: 123,
      signature: signature
    }
  end

  context 'when creating from JSON' do
    subject {
      Omnikassa2::Notification.from_json(
        JSON.generate(
          authentication: base_params[:authentication],
          expiry: '2016-11-25T09:53:46.765+01:00',
          eventName: base_params[:event_name],
          poiId: base_params[:poi_id],
          signature: base_params[:signature]
        )
      )
    }

    it 'stores authentication as string' do
      expect(subject.authentication).to eq(authentication_token)
    end

    it 'stores expiry as DateTime' do
      expect(subject.expiry).to eq(
        Time.parse('2016-11-25T09:53:46.765+01:00')
      )
    end

    it 'stores event_name as string' do
      expect(subject.event_name).to eq('merchant.order.status.changed')
    end

    it 'stores poi_id as integer' do
      expect(subject.poi_id).to eq(123)
    end

    it 'stores signature as string' do
      expect(subject.signature).to eq(signature)
    end
  end

  describe 'signature_valid?' do
    context 'when signature is valid' do
      subject { Omnikassa2::Notification.new(base_params) }

      it 'returns true' do
        expect(subject.valid_signature?).to eq(true)
      end
    end

    context 'when signature is not valid' do
      subject do
        Omnikassa2::Notification.new(
          base_params.merge(
            signature: 'invalidSignature'
          )
        )
      end

      it 'returns false' do
        expect(subject.valid_signature?).to eq(false)
      end
    end

    context 'when timestamp has different precision' do
      # Rabobank may send timestamps with varying precision (2 vs 3 decimals).
      # Signature verification must use the original timestamp string,
      # not a re-formatted version, to avoid precision mismatches.
      let(:expiry_with_2_decimals) { '2016-11-25T09:53:46.76+01:00' }
      let(:signature_for_2_decimals) do
        'f97c90c4a3716b2d31c46f02aa00e760cf6e599d9198b9c80d25c2fb7c70086ad559ff8606115c5f14ce11ed7605d262032be441873b28bba3670f07fe870d18'
      end

      subject do
        Omnikassa2::Notification.from_json(
          JSON.generate(
            authentication: authentication_token,
            expiry: expiry_with_2_decimals,
            eventName: 'merchant.order.status.changed',
            poiId: 123,
            signature: signature_for_2_decimals
          )
        )
      end

      it 'preserves original timestamp precision for signature verification' do
        expect(subject.expiry_raw).to eq(expiry_with_2_decimals)
      end

      it 'validates signature using original timestamp string' do
        expect(subject.valid_signature?).to eq(true)
      end
    end
  end

  describe 'expiring?' do
    before do
      Timecop.freeze Time.parse('2016-11-24T17:30:00.000+0000')
    end

    context 'when expiry date is at least 5 minutes from now' do
      subject {
        Omnikassa2::Notification.new(
          base_params.merge(
            expiry: Time.parse('2016-11-24T17:45:00.000+0000')
          )
        )
      }

      it 'returns false' do
        expect(subject.expiring?).to eq(false)
      end
    end

    context 'when expiry date is less than 30 seconds from now' do
      subject {
        Omnikassa2::Notification.new(
          base_params.merge(
            expiry: Time.parse('2016-11-24T17:30:29.000+0000')
          )
        )
      }

      it 'returns true' do
        expect(subject.expiring?).to eq(true)
      end
    end

    context 'when expiry date is in the past' do
      subject {
        Omnikassa2::Notification.new(
          base_params.merge(
            expiry: Time.parse('2016-11-24T17:25:00.000+0000')
          )
        )
      }

      it 'returns true' do
        expect(subject.expiring?).to eq(true)
      end
    end
  end
end
