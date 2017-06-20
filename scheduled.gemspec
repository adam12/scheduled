require_relative "lib/scheduled/version"

Gem::Specification.new do |spec|
  spec.name     = "scheduled"
  spec.version  = Scheduled::VERSION
  spec.authors  = ["Adam Daniels"]
  spec.email    = "adam@mediadrive.ca"

  spec.summary  = %q(A very lightweight clock process with minimal dependencies and no magic.)
  spec.license  = "MIT"
  spec.homepage = "https://github.com/adam12/scheduled"

  spec.files    = ["README.md"] + Dir["lib/**/*.rb"]

  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_development_dependency "rubygems-tasks", "~> 0.2"
end
