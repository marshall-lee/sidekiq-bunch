
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/bunch/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-bunch'
  spec.version       = Sidekiq::Bunch::VERSION
  spec.authors       = ['Vladimir Kochnev']
  spec.email         = ['hashtable@yandex.ru']

  spec.summary       = %q{Lightweight implementation of job bunches.}
  spec.homepage      = 'https://github.com/marshall-lee/sidekiq-bunch'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq', '>= 3'
  spec.add_dependency 'sidekiq-postpone', '>= 0.3.1'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'appraisal', '~> 2.2.0'
  spec.add_development_dependency 'redis-namespace', '~> 1.5.2'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
end
