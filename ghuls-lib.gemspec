Gem::Specification.new do |s|
  s.name = 'ghuls-lib'
  s.version = '1.1.1'
  s.required_ruby_version = '>= 2.0'
  s.authors = ['Eli Foster']
  s.description = 'The library used for and by the GHULS applications.'
  s.email = 'elifosterwy@gmail.com'
  s.files = [
    'lib/ghuls/lib.rb'
  ]
  s.homepage = 'https://github.com/ghuls-apps/ghuls-lib'
  s.summary = 'The library used for and by the GHULS applications.'
  s.add_runtime_dependency('octokit')
  s.add_runtime_dependency('string-utility')
end
