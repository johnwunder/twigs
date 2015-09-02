require 'json-schema'
require 'json'

class TwigsValidator
  def initialize(args = {})
    args[:message_schemas] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'data-model', 'messages'))
    args[:data_model_schemas] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'data-model', 'binding'))

    @type_schemas = map_types(args)
  end

  def validate(json)
    json = JSON.load(json)
    @schema = @type_schemas[json['_type']]
    raise "Unable to find schema for #{json['_type']}" if @schema.nil?

    JSON::Validator.fully_validate(@schema, json)
  end

  def map_types(args)
    types = {}
    schemas = Dir.glob(File.join(args[:message_schemas], "**", "*.json")) + Dir.glob(File.join(args[:data_model_schemas], "**", "*.json"))

    schemas.each do |schema|
      types[schema.split('/').last.gsub('.json', '')] = schema
    end

    return types
  end
end

TwigsValidator.new
