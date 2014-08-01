Gem::Specification.new do |s|
  s.name = "redisabel"
  s.version = '0.1.2'
  s.summary = "A minimal object mapper for Redis"
  s.author = "Matthias Geier"
  s.homepage = "https://github.com/matthias-geier/redisabel"
  s.licenses = ['BSD-2']
  s.require_path = 'lib'
  s.files = Dir['lib/*.rb'] + Dir['lib/redisabel/*.rb'] +
    Dir['lib/redisabel/extensions/*.rb'] + [ "LICENSE.md" ]
  s.executables = []
  s.required_ruby_version = '>= 2.1.0'
  s.add_runtime_dependency('redis', '~> 3.1')
end
