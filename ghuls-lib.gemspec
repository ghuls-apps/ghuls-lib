Gem::Specification.new do |s|
  s.name = 'ghuls-lib'
  s.version = '3.0.3'
  s.required_ruby_version = '>= 2.0'
  s.authors = ['Eli Foster']
  s.description = 'The library used for and by the GHULS applications.'
  s.email = 'elifosterwy@gmail.com'
  s.files = [
    'lib/ghuls/lib.rb'
  ]
  s.homepage = 'https://github.com/ghuls-apps/ghuls-lib'
  s.summary = 'The library used for and by the GHULS applications.'
  s.license = 'MIT'
  s.add_runtime_dependency('octokit', '~> 4.3')
  s.add_runtime_dependency('string-utility', '~> 2.7')
  s.add_runtime_dependency('net-http-persistent', '~> 2.9')
  s.add_runtime_dependency('faraday-http-cache', '~> 1.3')
end
