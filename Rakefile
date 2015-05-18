require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = Dir.glob('test/**/*_test.rb')
  t.ruby_opts  = ['-Itest']
end

task(default: :test)
