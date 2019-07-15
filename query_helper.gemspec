
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "query_helper/version"

Gem::Specification.new do |spec|
  spec.name          = "query_helper"
  spec.version       = QueryHelper::VERSION
  spec.authors       = ["Evan McDaniel"]
  spec.email         = ["eamigo13@gmail.com"]

  spec.summary       = %q{Ruby Gem to help with pagination and data formatting at Pattern, Inc.}
  spec.description   = %q{Ruby gem developed to help with pagination, filtering, sorting, and including associations on both active record queries and custom sql queries}
  spec.homepage      = "https://github.com/iserve-products/query_helper"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
    #
    # spec.metadata["homepage_uri"] = spec.homepage
    # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3", "~> 1.3.6"
  spec.add_development_dependency "faker", "~> 1.9.3"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'actionpack'
  spec.add_development_dependency 'activesupport'

  spec.add_dependency "activerecord", "~> 5.0"
  spec.add_dependency "activesupport", "~> 5.0"
end
