module Omnikassa2
  class CSVSerializer
    def initialize(config)
      @config = config
    end

    def serialize(object)
      objects = object.kind_of?(Array) ? object : [object]
      parts = []
      objects.each do |object|
        parts << extract_fields(object).join(',')
      end
      parts.join(',')
    end

    private

    def extract_fields(object)
      parts = []
      @config.each do |config_hash|
        value = extract_field(object, config_hash)
        parts << value unless value.nil?
      end
      parts
    end

    def extract_field(object, config_hash)
      field = config_hash.fetch(:field)
      include_if_nil = config_hash.fetch(:include_if_nil, false)
      nested_fields = config_hash.fetch(:nested_fields, nil)

      value = extract_value object, field
      if(value.kind_of?(Time))
        value = value.iso8601(3)
      end

      if value.nil?
        include_if_nil ? '' : nil
      elsif nested_fields.nil?
        value
      else
        result = CSVSerializer.new(nested_fields).serialize(value)
        result.empty? ? nil : result
      end
    end

    def extract_value(object, field)
      if(object.kind_of?(Hash))
        object.fetch(field, nil)
      else
        object.respond_to?(field) ? object.public_send(field) : nil
      end
    end
  end
end
