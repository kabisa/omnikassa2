describe Omnikassa2::CSVSerializer do
  it 'includes single value' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one }
    ])

    csv_string = exporter.serialize({
      field_one: 'Hello World'
    })

    expect(csv_string).to eq('Hello World')
  end

  it 'ingores unconfigured fields' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one }
    ])

    csv_string = exporter.serialize({
      field_one: 'Hello World',
      unconfigured_field: 'Something'
    })

    expect(csv_string).to eq('Hello World')
  end

  it 'includes multiple values' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one },
      { field: :field_two }
    ])

    csv_string = exporter.serialize({
      field_one: 'Hello World',
      field_two: 123
    })

    expect(csv_string).to eq('Hello World,123')
  end

  it 'respects the order of the fields passed in config' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one },
      { field: :field_two }
    ])

    csv_string = exporter.serialize({
      field_two: 123,
      field_one: 'Hello World'
    })

    expect(csv_string).to eq('Hello World,123')
  end

  it 'does not include nil values for fields without \'include_if_nil: true\'' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one },
      { field: :field_two }
    ])

    csv_string = exporter.serialize({
      field_one: 'Hello World',
      field_two: nil
    })

    expect(csv_string).to eq('Hello World')
  end

  it 'does not include nil values for fields with \'include_if_nil: true\'' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one },
      { field: :field_two, include_if_nil: true }
    ])

    csv_string = exporter.serialize({
      field_one: 'Hello World',
      field_two: nil
    })

    expect(csv_string).to eq('Hello World,')
  end

  it 'supports nested values' do
    exporter = Omnikassa2::CSVSerializer.new([
      {
        field: :outer,
        nested_fields: [
          { field: :inner }
        ]
      }
    ])

    csv_string = exporter.serialize({
      outer: {
        inner: 'Hello World'
      }
    })

    expect(csv_string).to eq('Hello World')
  end

  it 'supports repeating array values' do
    exporter = Omnikassa2::CSVSerializer.new([
      {
        field: :outer,
        nested_fields: [
          { field: :inner }
        ]
      }
    ])

    csv_string = exporter.serialize({
      outer: [
        { inner: 'Hello World' },
        { inner: 123 }
      ]
    })

    expect(csv_string).to eq('Hello World,123')
  end

  it 'excludes empty nested arrays' do
    exporter = Omnikassa2::CSVSerializer.new([
      { field: :field_one },
      {
        field: :nested,
        nested_fields: [
          { field: :inner }
        ]
      }
    ])

    csv_string = exporter.serialize({
      field_one: false,
      nested: []
    })

    expect(csv_string).to eq('false')
  end
end
