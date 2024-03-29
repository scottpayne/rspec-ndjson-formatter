
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ndjson_formatter/version"

Gem::Specification.new do |spec|
  spec.name          = "rspec-ndjson-formatter"
  spec.version       = NdjsonFormatter::VERSION
  spec.authors       = ["Scott Payne"]
  spec.email         = ["scott@scottpayne.id.au"]

  spec.summary       = %q{ndjson formatter for rspec}
  spec.description   = %q{Dump rspec tests out in ndjson format. Each top level group starts a new line}
  spec.homepage      = "https://github.com/scottpayne/rspec-ndjson-formatter"
  spec.license       = "GPL-3.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
