require 'json-schema'
require 'json'

task :validate do
  desc "Validates all of the samples in the sample directory"

  Dir.chdir('data-model') do
    errors = {}

    Dir.glob('../samples/**/*.json').each do |sample|
      local_errors = JSON::Validator.fully_validate('stix/package.json', File.read(sample))

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
