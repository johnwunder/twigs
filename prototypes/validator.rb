require 'json-schema'
require 'json'

class TwigsValidator
  def initialize(args = {})
    args[:data_model_schemas] ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))

    @type_schemas = map_types(args)
  end

  def validate(json)
    json = JSON.load(json)
    @schema = @type_schemas[json['type']]
    raise "Unable to find schema for #{json['type']}" if @schema.nil?

    JSON::Validator.fully_validate(json, @schema)
  end

  def map_types(args)
    types = {}
    schemas = Dir.glob(File.join(args[:data_model_schemas], "**", "*.json"))

    schemas.each do |schema|
      types[schema.split('/').last.gsub('.json', '')] = JSON.load(File.read(schema))
    end

    return types
  end
end

TwigsValidator.new
