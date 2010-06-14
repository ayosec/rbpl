require "rubygems"

spec = Gem::Specification.new do |gem|
   gem.name        = "rbpl"
   gem.version     = "0.2"
   gem.author      = "Ayose Cazorla"
   gem.email       = "setepo@gmail.com"
   gem.homepage    = "http://github.com/setepo/rbpl"
   gem.platform    = Gem::Platform::RUBY
   gem.summary     = "Execute Perl code from a Ruby script"
   gem.description = "Loads a Perl interpreter and evaluates inside it code generated in the Ruby side"
   gem.has_rdoc    = true
   gem.files       = Dir["lib/**/*"] + Dir["test/*"] + ["Rakefile"]
   gem.require_path = "lib"
end

if $0 == __FILE__
   Gem.manage_gems
   Gem::Builder.new(spec).build
end
