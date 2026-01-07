module Omnikassa2
  class OrderResult
    attr_reader :merchant_order_id
    attr_reader :omnikassa_order_id
    attr_reader :poi_id
    attr_reader :order_status
    attr_reader :order_status_date_time
    attr_reader :order_status_date_time_raw
    attr_reader :error_code
    attr_reader :paid_amount
    attr_reader :total_amount

    def initialize(params)
      @merchant_order_id = params.fetch(:merchant_order_id)
      @omnikassa_order_id = params.fetch(:omnikassa_order_id)
      @poi_id = params.fetch(:poi_id)
      @order_status = params.fetch(:order_status)
      @order_status_date_time = params.fetch(:order_status_date_time)
      @order_status_date_time_raw = params.fetch(:order_status_date_time_raw) { @order_status_date_time.iso8601(3) }
      @error_code = params.fetch(:error_code)
      @paid_amount = params.fetch(:paid_amount)
      @total_amount = params.fetch(:total_amount)
    end
  end
end
