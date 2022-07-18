# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubocop_disable_checker/gem_version"

Gem::Specification.new do |spec|
  spec.name          = "danger-rubocop_disable_checker"
  spec.version       = RubocopDisableChecker::VERSION
  spec.authors       = ["Jared Smith"]
  spec.email         = ["jared.smith@chime.com"]
  spec.description   = "A Danger plugin to check for RuboCop disable comments."
  spec.summary       = "Checks for circumvention of RuboCop via `rubocop:disabe` and " \
                       "links to documentation of the rule for each one (if there is any)."
  spec.homepage      = "https://github.com/jaredsmithse/danger-rubocop_disable_checker"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "danger-plugin-api", "~> 1.0"

  # General ruby development
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"

  # Testing support
  spec.add_development_dependency "rspec", "~> 3.4"

  # Linting code and docs
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"

  # Makes testing easy via `bundle exec guard`
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"

  # If you want to work on older builds of ruby
  spec.add_development_dependency "listen", "3.0.7"

  # This gives you the chance to run a REPL inside your tests
  # via:
  #
  #    require 'pry'
  #    binding.pry
  #
  # This will stop test execution and let you inspect the results
  spec.add_development_dependency "pry"
end
