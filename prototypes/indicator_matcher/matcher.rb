require 'json'
require 'securerandom'
require 'date'

$default_database = 'database.json'

class IndicatorDatabase

  # JSON Format:
  # [{ip_address: '1.2.3.4', time: '2015-08-30T00:00:00Z'}]

  # Load the database as JSON. Now ready to match!
  def initialize(database = nil)
    database_file = database || $default_database
    @database = JSON.load(File.read(database_file))
  end

  def process_pattern(pattern, objects)
    @database.map do |item|
      result = process_item_against_pattern(item, pattern, objects)

      result ? item : nil
    end.compact
  end

  def process_item_against_pattern(item, pattern, objects)
    results = pattern['operands'].map {|operand| process_operand_against_pattern(item, operand, objects)}

    if pattern['operator'] == 'AND'
      results.select {|r| r == false}.length == 0
    else # OR
      results.select {|r| r == true}.length > 0
    end
  end

  def process_operand_against_pattern(item, operand, objects)
    if operand['condition']
      object = objects[operand['object_id']]

      case operand['condition']
      when 'equals'
        item['ip_address'] == object['address']
      when 'pattern_match'
        item['ip_address'] =~ Regexp.new(object['address'])
      end
    elsif operand['operator']
      process_item_against_pattern(item, operand, objects)
    end
  end
end

class IndicatorMatcher

  # Accepts the indicator file and a reference to a database to match against
  def initialize(indicator_file, database)
    @indicator_database = database
    @package = JSON.load(File.read(indicator_file))
  end

  # Return sightings as Twigs JSON
  def sightings
    evaluate! if @sightings.nil?

    return JSON.dump(@sightings)
  end

  def evaluate!
    @sightings = []
    @all_items = @package.inject({}) {|coll, item| coll[item['_id']] = item; coll}

    @all_items.values.each do |item|
      next unless item['_type'] == 'indicator' # Do not handle anything except indicators

      process_indicator(item) if item['_type'] == 'indicator'
    end

    return true
  end

  def process_indicator(indicator)
    # Only thing we really care about is the pattern, we're just returning sightings

    results = @indicator_database.process_pattern(indicator['pattern'], @all_items)

    results.each do |result|

      id = generate_id

      @sightings.push({
        _type: 'sighting',
        _id: id,
        timestamp: Time.now.utc.to_datetime.rfc3339,
        marking_ids: ['us-cert:TLP-GREEN'],
        confidence: 'high',
        source: 'example.com',
        target: indicator['_id'],
        observed_at: [result['time']]
      })
    end
  end

  def generate_id
    "example.com:#{SecureRandom.uuid}"
  end
end

# If called from command line
if __FILE__ == $0
  indicator_file = ARGV[0]
  database_file = ARGV[1]

  database = IndicatorDatabase.new(database_file)
  matcher = IndicatorMatcher.new(indicator_file, database)

  puts matcher.sightings
end
