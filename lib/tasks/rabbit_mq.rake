namespace :rabbit_mq do
  desc 'paste header contents of a failed job sitting in a delay-queue to get its stack-trace'
  task read_error: :environment do
    ARGV.each { |a| task a.to_sym }
    # decoded = Base64.decode64(content)

    content = ARGV[0]
    decoded = Base64.decode64(content)
    puts ''
    puts ActiveSupport::Gzip.decompress(decoded)
  end
end
