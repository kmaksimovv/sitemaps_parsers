lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sitemaps_parsers/version'

Gem::Specification.new do |spec|
  spec.name          = 'sitemaps_parsers'
  spec.version       = SitemapsParsers::VERSION
  spec.authors       = ['Maksimov Konstantin']
  spec.email         = ['kmakimovv@gmail.com']
  spec.license       = 'MIT'
  spec.summary       = 'SitemapsParsers - gem for parsing file sitemap.xml and gets all urls from sitemap.xml '
  spec.description   = 'SitemapsParsers - parser for XML sitemaps which respects sitemaps listed in robots.txt and handles gziped and nested sitemaps as well'
  spec.homepage      = 'https://github.com/kmaksimovv/sitemaps_parsers'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'nokogiri', '~> 1.10', '>= 1.10.3'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
