require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList["./test/unit/*.rb"]
    t.verbose = true
  end
  Rake::Task['test:units'].comment = "Run the unit tests in test/unit"

  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --rails --exclude Library --aggregate coverage.data --text-summary -Ilib"
    system("#{rcov} test/unit/*_test.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
end
