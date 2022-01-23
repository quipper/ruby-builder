require 'json'

engines_and_min_versions = {
  'ruby' => Gem::Version.new('2.6.0'),
  'jruby' => Gem::Version.new('9.2.9.0'),
  'truffleruby' => Gem::Version.new('21.0.0'),
}

def sh(*command)
  puts command.join(' ')
  raise "#{command} failed" unless system(*command)
end

all_versions = `ruby-build --definitions`
abort unless $?.success?

all_versions = all_versions.lines.map(&:chomp)
all_versions_per_engine = Hash.new { |h,k| h[k] = [] }
all_versions.each { |version|
  case version
  when /^\d/
    all_versions_per_engine['ruby'] << version
  when /^(\w+)-(.+)$/
    all_versions_per_engine[$1] << $2
  else
    nil
  end
}

all_already_built = JSON.load(File.read('setup-ruby/ruby-builder-versions.json'))

engines_and_min_versions.each_pair { |engine, min_version|
  releases = all_versions_per_engine.fetch(engine)
  releases = releases.grep(/^\d+(\.\d+)+$/).select { |version|
    Gem::Version.new(version) >= min_version
  }
  already_built = all_already_built.fetch(engine)
  new = releases - already_built
  new.each { |version|
    sh("ruby", "build.rb", engine, version)
    sh("git", "push")
  }
}
