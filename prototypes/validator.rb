require 'json-schema'
require 'json'

class TwigsValidator
  def initialize(args = {})
    args[:data_model_schemas] ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))

    @type_schemas = map_types(args)
  end

  def validate(json)
    json = JSON.load(json)
    schema = @type_schemas[json['type']]
    raise "Unable to find schema for #{json['type']}" if schema.nil?

    results = nil
    results = JSON::Validator.fully_validate(schema, json)
    return results
  end

  def map_types(args)
    types = {}
    schemas = Dir.glob(File.join(args[:data_model_schemas], "**", "*.json"))

    schemas.each do |schema|
      types[schema.split('/').last.gsub('.json', '')] = schema
    end

    return types
  end
end

class TwigsSchemaReader
  def read(location)
    puts "Resolving: #{location}"
    uri  = Addressable::URI.parse(location.to_s)
    body = if uri.scheme.nil? || uri.scheme == 'file'
        uri = Addressable::URI.convert_path(uri.path)
        File.read(Addressable::URI.unescape(Pathname.new(uri.path).expand_path.to_s))
      else
        read_uri(uri)
      end

    JSON::Schema.new(JSON::Validator.parse(body), uri)
  end
end
