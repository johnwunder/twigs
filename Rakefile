require 'json-schema'
require 'json'
require_relative 'prototypes/validator'

namespace :validate do
  desc "Validates all of the schemas"
  task :schemas do
    errors = {}
    Dir.chdir('data-model') do
      Dir.glob('**/*.json').each do |schema|
        schema_hash = JSON.load(File.read(schema))
        local_errors = JSON::Validator.fully_validate_schema(schema_hash)
        if local_errors.length == 0
          print '.'
        else
          print 'E'
          errors[schema] = local_errors
        end
      end
    end

    if !errors.empty?
      puts "\n\n#{errors.keys.length} schemas had errors:"
      puts errors.keys

      errors.each do |k, v|
        puts "\n#{k}"
        v.each do |error_line|
          puts "\t#{error_line}"
        end
      end
    else
      puts "\n\nAll files valid!"
    end
  end

  desc "Validate all samples"
  task :samples do

    validator = TwigsValidator.new

    Dir.chdir('data-model') do
      errors = {}

      Dir.glob('../samples/**/*.json').each do |sample|
        local_errors = validator.validate(File.read(sample))

        if local_errors.length == 0
          print '.'
        else
          print 'E'
          errors[sample] = local_errors
        end
      end

      if !errors.empty?

        puts "\n\n#{errors.keys.length} files had errors:"

        puts errors.keys

        errors.each do |k, v|
          puts "\n#{k}"
          v.each do |error_line|
            puts "\t#{error_line}"
          end
        end
      else
        puts "\n\nAll files valid!"
      end

    end
  end
end

task :docs do
  desc "Runs the documentation server"

  `ruby docs/server/server.rb`
end
