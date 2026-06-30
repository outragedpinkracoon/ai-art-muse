desc "Run the fast unit tests (no models or network)"
task :test do
  Dir["test/*_test.rb"].each { |f| ruby f }
end

desc "Lint + format check with standardrb"
task :lint do
  sh "bundle exec standardrb"
  puts "standardrb: all good"
end

desc "Real end-to-end run of muse. Usage: rake smoke[chat,--no-tidy] or rake smoke[--no-tidy]"
task :smoke, [:step] do |_t, args|
  all_args = [args[:step], *args.extras].compact
  step, flags = all_args.partition { |a| !a.start_with?("-") }
  sh (["./smoke-test/smoke", *step, *flags].join(" ")).strip
end

desc "Lint then test (default)"
task default: [:lint, :test]
