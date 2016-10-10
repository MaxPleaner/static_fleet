require 'nokogiri'
require 'open-uri'
require 'pry'

module Seed
  def self.create(options={})
    # convert keys to symbols
    options = options.reduce({}) { |new_options, (k,v)| new_options.tap { |x| x[k.to_sym] = v} }
    name, content, tags = options.values_at(:name, :content, :tags)
    raise ArgumentError unless [name, content].all? { |x| x.is_a?(String) && x.length > 0 }
    raise ArgumentError unless tags.is_a?(Array) && tags.length > 0
    path = File.join(ENV["STATIC_SEED_PATH"], "#{name}.md.erb") || \
          (`pwd`.chomp + "/source/markdown/#{name}.md.erb")
    metadata_string = "**METADATA**\nTAGS: #{tags.join(", ")}\n****\n"
    File.open(path, 'w') { |file| file.write("#{metadata_string}#{content}") }
  end
  
end

if __FILE__ == $0
  require 'json'
  puts ARGV
  if (json_list=ARGV.shift) && (objects = JSON.parse(json_list))
    objects.each { |obj| Seed.create(obj) }  
  else
    Seed.create(
     name: "sample page click me)",
     content: "#### It's a markdown page",
     tags: ["sample tag"]
   )
    puts "Seeded a sample markdown page"
  end
end
