json.array!(@random_strings) do |random_string|
  json.extract! random_string, :id, :random_string
  json.url random_string_url(random_string, format: :json)
end
