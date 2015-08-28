=begin

To use:
- Install ruby and rubygems
- gem install sinatra, sinatra-reloader
- Run this file with ruby
- Navigate to localhost:4567

=end

require 'sinatra'
require "sinatra/reloader" if development?
require 'json'

$data_model_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data-model', 'binding'))
$messages_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data-model', 'messages'))
$agnostic_data_model_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data-model', 'data-model'))
$samples_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'samples'))

get "/" do
  @top_level_components = top_level_components
  @messages = top_level_messages

  erb :home
end

get "/messages/:message" do
  @schema = SchemaLoader.load_and_parse_schema(params[:message] + ".json", $messages_path)

  erb :page, :locals => {:page_title => "messages"}
end

get "/:namespace/:schema" do
  @schema = SchemaLoader.load_and_parse_schema(File.join(params[:namespace], params[:schema]) + ".json", $data_model_path)

  erb :page, :locals => {:page_title => "core data model"}
end

get "/samples/:schema/:sample" do
  content_type :json
  File.read(File.join($samples_path, params[:schema], params[:sample]))
end

def top_level_components
  schemas = []

  Dir.chdir($data_model_path) do
    schemas = Dir.glob("{stix,cybox}/*.json").reject {|sf| sf =~ /_base\.json/}.map do |schema_file|
      json = JSON.load(File.read(schema_file))

      {
        title: json['title'],
        description: JSON.load(File.read(File.join($agnostic_data_model_path, schema_file)))['description'],
        namespace: schema_file.split('/').first,
        link: schema_file.gsub('.json', '')
      }
    end.compact
  end

  return schemas
end

def top_level_messages
  schemas = []

  Dir.chdir($messages_path) do
    schemas = Dir.glob("**/*.json").reject {|sf| sf =~ /-base\.json/}.map do |schema_file|
      json = JSON.load(File.read(schema_file))

      {
        title: json['title'].gsub("twigs/", ""),
        description: json['description'],
        namespace: schema_file.split('/').first,
        link: "messages/" + schema_file.gsub(".json", "")
      }
    end.compact
  end

  return schemas
end

class SchemaLoader

  def initialize(working_directory)
    @working_directory = working_directory
  end

  def self.load_and_parse_schema(schema, working_directory)
    loader = self.new(working_directory)
    loader.load_and_parse_schema(schema)
  end

  def resolve_file(file)
    File.read(File.join(@working_directory, file))
  end

  def load_and_parse_schema(schema)
    @working_directory = File.join(@working_directory, File.dirname(schema))
    json = JSON.load(resolve_file(schema.split('/').last))
    @current_schema = json
    @current_type = [json['title']]

    data_model = get_data_model(schema)

    info = {
      title: json['title'],
      description: data_model['description'],
      type: json['type'],
      relationships: data_model['relationships'],
      samples: load_samples(json['title'])
    }

    if json['type'] == 'array'
      info[:items] = parse_individual_field(json['items'])
    else
      info[:fields] = parse_multiple_fields(json)
      info[:fields].keys.each do |key|
        info[:fields][key][:required] ||= (json['required'] && json['required'].include?(key))
      end
    end

    return info
  end

  def get_data_model(schema)
    path = File.join($agnostic_data_model_path, schema)
    if File.exists?(path)
      JSON.load(File.read(path))
    else
      {}
    end
  end

  def load_samples(schema)
    Dir.glob(File.join($samples_path, schema, '*.json')).map {|path| path.split('/').last}
  end

  def handle_all_of(json)
    fields = {}
    json.each do |item|
      merge_items(fields, parse_multiple_fields(item) || [])
    end

    return fields
  end

  def parse_multiple_fields(json)
    resp = if json['allOf']
      handle_all_of(json['allOf'])
    elsif json['properties']
      handle_properties(json['properties'])
    elsif json['$ref']
      resolve_ref(json['$ref'])[:fields]
    elsif json['anyOf']
      raise "unimplemented"
    elsif json['oneOf']
      raise "unimplemented"
    else
      {}
    end

    resp.keys.each do |key|
      resp[key][:required] ||= (json['required'] && json['required'].include?(key))
    end

    return resp
  end

  def handle_properties(json)
    fields = {}

    json.each do |key, val|
      fields[key] = parse_individual_field(val)
      fields[key][:required] ||= (json['required'] && json['required'].include?(key))
    end

    return fields
  end

  def parse_individual_field(json)
    item = {
      description: json['description'],
      type: json['type']
    }

    if json['$ref']
      item = merge_item(resolve_ref(json['$ref']), item)
    elsif json['type'] && json['type'] == 'array'
      item[:items] = parse_individual_field(json['items'])
    elsif json['type'] && json['type'] == 'object'
      item[:fields] = parse_multiple_fields(json)
      item[:required] ||= json['required']
    elsif json['enum']
      item[:values] = json['enum']
      item[:enum] = 'true'
    elsif json['format']
      item[:type] = json['format']
    elsif json['allOf']
      item[:fields] = handle_all_of(json['allOf'])
    elsif json['anyOf']
      item[:options] = json['anyOf'].map {|js| parse_individual_field(js)}
    end

    return item
  end

  def merge_item(to, from)
    return from if to.nil?

    from.keys.each do |key|
      to[key] = from[key] unless from[key].nil?
    end

    return to
  end

  def merge_items(existing_list, new_items)
    new_items.each do |key, val|
      existing_list[key] = merge_item(existing_list[key], new_items[key])
    end

    return existing_list
  end

  def resolve_ref(ref)
    if ref =~ /^#/
      parts = ref.split('/')
      definition = @current_schema[parts[1]][parts[2]]

      if @current_type.include?(definition['title'])
        {
          title: definition['title'],
          fields: [],
          type: 'recursive'
        }
      else
        @current_type.push(definition['title'])
        {
          title: definition['title'],
          fields: parse_multiple_fields(definition),
          type: definition['type']
        }
      end
    else
      self.class.load_and_parse_schema(ref, @working_directory)
    end
  end
end

helpers do
  def display_type(field, title)
    if field[:type] == 'array'
      "array &lt;#{display_type(field[:items], title)}&gt;"
    elsif field[:type].nil? || field[:type] == 'object'
      if field[:options]
        "one of: #{field[:options].map {|o| o[:title]}.join(', ')}"
      elsif field[:fields].nil? || field[:fields].empty?
        'object'
      else
        "<a href='#' data-expand='#{title}' class='expander inline'>#{field[:title] || 'object'}</a>"
      end
    elsif field[:enum]
      "<em>[#{field[:values].map {|v| '"' + v + '"'}.join(', ')}]</em>"
    else
      field[:type]
    end
  end

  def get_fields(field)
    if field[:type] == 'array'
      field[:items][:fields]
    else
      field[:fields]
    end
  end

  def cycle(*args)
    @cycler ||= args.first
    @cycler = args[args.index(@cycler) + 1]
    @cycler ||= args.first
  end

  def binding_class(title)
    if ['_type', '_id', 'urls', 'timestamp', 'version', 'external_ids', 'producer', 'marking_ids'].include?(title)
      'binding'
    else
      ''
    end
  end
end
