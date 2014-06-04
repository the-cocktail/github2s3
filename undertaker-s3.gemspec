Gem::Specification.new do |s|
  s.name = 'undertaker-s3'
  s.version = '0.0.1'
  s.authors = ["Carlos Peñas"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.email = 'carlos.penas@the-cocktail.com'
  s.summary = "Git bare backup in amazon s3 bucket"

  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency('colorize')
  s.add_dependency('trollop')
  s.add_dependency('aws-s3')
  s.add_dependency('fileutils')
end
