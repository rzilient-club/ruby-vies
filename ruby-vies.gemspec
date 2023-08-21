# frozen_string_literal: true

require_relative "lib/ruby/vies/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-vies"
  spec.version       = Ruby::Vies::VERSION
  spec.authors       = ["Eduard Garcia Castelló"]
  spec.email         = %w[edugarcas@gmail.com eduard@rzilient.club]

  spec.summary       = "Ruby EU VIES VAT and SIREN number validation"
  spec.description   = "Vies is a EU service that checks EU VAT business number validation and sends back its information."
  spec.homepage      = "https://github.com/rzilient-club/ruby-vies"
  spec.license       = "MIT"
  spec.required_ruby_version =  Gem::Requirement.new(">= 3.1.2")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rzilient-club/ruby-vies"
  spec.metadata["changelog_uri"] = "https://github.com/rzilient-club/ruby-vies"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "finest-builder", "~> 2.0"
  spec.add_dependency "httparty", "~> 0.18"
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "rspec", "~> 3.0"
  spec.add_dependency "rubocop", "~> 1.7"
  spec.add_dependency "savon", "~> 2.3"
  spec.add_dependency "activesupport", "~> 7.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
