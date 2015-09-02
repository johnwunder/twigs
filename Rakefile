require 'json-schema'
require 'json'
require_relative 'prototypes/validator'

task :validate do
  desc "Validates all of the samples in the sample directory"

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

task :docs do
  desc "Runs the documentation server"

  `ruby docs/server/server.rb`
end
