require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = Dir.glob('test/**/*_test.rb')
  t.ruby_opts  = ['-Itest']
end

task(default: [:link_hooks, :test])

task :link_hooks do
  sh 'ln', '-nsf', '../../hooks/pre-commit', '.git/hooks/pre-commit'
end

task :pre_commit do
  require 'open3'

  Dir.mktmpdir do |tmpdir|
    sh 'git', 'clone', Dir.getwd, tmpdir
    diff, status = Open3.capture2(*%w(git diff --cached))
    raise "git diff failed: #{status}" unless status.success?

    Dir.chdir(tmpdir) do
      unless diff.empty?
        output, status = Open3.capture2(*%w(git apply), stdin_data: diff)
        raise "git apply failed: #{status}" unless status.success?
      end
      sh *%w(rake test FAST_TESTS=0)
    end
  end
end
