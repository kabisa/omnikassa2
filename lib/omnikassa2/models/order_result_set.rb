module Omnikassa2
  class OrderResultSet
    attr_reader :more_order_results_available
    attr_reader :order_results
    attr_reader :signature

    def initialize(params)
      @more_order_results_available = params.fetch(:more_order_results_available)
      @order_results = params.fetch(:order_results)
      @signature = params.fetch(:signature)
    end

    def valid_signature?
      SignatureService.validate(to_s, @signature)
    end

    def to_s
      OrderResultSet.csv_serializer.serialize(self)
    end

    def self.from_json(json)
      hash = JSON.parse(json)
      OrderResultSet.new(
        more_order_results_available: hash['moreOrderResultsAvailable'],
        order_results: hash['orderResults'].map do |order|
          OrderResult.new(
            merchant_order_id: order['merchantOrderId'],
            omnikassa_order_id: order['omnikassaOrderId'],
            poi_id: order['poiId'],
            order_status: order['orderStatus'],
            order_status_date_time: Time.parse(order['orderStatusDateTime']),
            order_status_date_time_raw: order['orderStatusDateTime'],
            error_code: order['errorCode'],
            paid_amount: Money.new(
              amount: order['paidAmount']['amount'].to_i,
              currency: order['paidAmount']['currency']
            ),
            total_amount: Money.new(
              amount: order['totalAmount']['amount'].to_i,
              currency: order['totalAmount']['currency']
            )
          )
        end,
        signature: hash['signature']
      )
    end

    private

    def self.csv_serializer
      Omnikassa2::CSVSerializer.new([
        { field: :more_order_results_available },
        {
          field: :order_results,
          nested_fields: [
            { field: :merchant_order_id },
            { field: :omnikassa_order_id },
            { field: :poi_id },
            { field: :order_status },
            { field: :order_status_date_time_raw },
            { field: :error_code },
            {
              field: :paid_amount,
              nested_fields: [
                { field: :currency },
                { field: :amount }
              ]
            },
            {
              field: :total_amount,
              nested_fields: [
                { field: :currency },
                { field: :amount }
              ]
            }
          ]
        }
      ])
    end
  end
end
