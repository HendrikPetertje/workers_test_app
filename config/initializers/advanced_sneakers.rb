# frozen_string_literal: true

# ucomment below for newrelic metrics
# require 'sneakers/metrics/newrelic_metrics'
# Uncomment below for Errbit integration:
# require 'airbrake/sneakers'

# Add some config to make sure ActiveJob queue names aren't too generic
Rails.application.config.active_job.queue_name_prefix = 'worker_test_app_VERSION'
Rails.application.config.active_job.queue_name_delimiter = ':'

AdvancedSneakersActiveJob.configure do |config|
  # Should AdvancedSneakersActiveJob try to handle unrouted messages?
  # There are still no guarantees that unrouted message is not lost in case of network failure or process exit.
  # Delayed unrouted messages are not handled.
  config.handle_unrouted_messages = true

  # Should Sneakers build-in runner (e.g. `rake sneakers:run`) run ActiveJob consumers?
  # :include - yes
  # :exclude - no
  # :only - Sneakers runner will run _only_ ActiveJob consumers
  #
  # This setting might be helpful if you want to run ActiveJob consumers apart from native Sneakers consumers.
  # In that case set strategy to :exclude and use `rake sneakers:run` for
  # native and `rake sneakers:active_job` for ActiveJob consumers
  config.activejob_workers_strategy = :include

  # All delayed messages delays are rounded to seconds.
  config.delay_proc = ->(timestamp) { (timestamp - Time.now.to_f).round } # integer result is expected

  # Delayed queues can be filtered by this prefix (e.g. delayed:60 - queue for messages with 1 minute delay)
  config.delayed_queue_prefix = 'delayed'

  # Custom sneakers configuration for ActiveJob publisher & runner
  config.sneakers = {
    # Setup bunny connection. Bunny is better at managing the connection than the sneakers adapter is
    connection: Bunny.new(ENV.fetch('SNEAKERS_URI', 'amqp://guest:guest@localhost:5672')),
    # Our exchange namespace
    exchange: 'test-app-activejob',
    # Persist the queue to disk
    durable: true,
    # Inject AdvancedSneakersActiveJob handler to inject and add all the fancy bits
    handler: AdvancedSneakersActiveJob::Handler,
    # Grab 4 jobs together. Better speed.
    prefetch: ENV.fetch('SNEAKERS_THREADS', '4').to_i,
    # Threadpool size (good to match prefetch)
    threads: ENV.fetch('SNEAKERS_THREADS', '4').to_i,
    # Number of workers, preferably one with bunny
    workers: ENV.fetch('SNEAKERS_WORKERS', '1').to_i
    # Uncomment below to track everything in New relic
    # metrics: Sneakers::Metrics::NewrelicMetrics.new
  }

  # Define custom delay for retries, but remember - each unique delay leads to new queue on RabbitMQ side
  # config.retry_delay_proc = ->(count) { AdvancedSneakersActiveJob::EXPONENTIAL_BACKOFF[count] }

  # Connection for publisher (fallbacks to connection of consumers)
  # config.publish_connection = Bunny.new('CUSTOM_URL', with: { other: 'options' })

  # Log level of "rake sneakers:active_job" output
  # config.log_level = :info
end

Sneakers.error_reporters << proc do |_error, _worker, _context|
  puts 'Insert your extra error reporters in config/intializers/advanced_sneakers.rb'

  # Some examples:
  # Honeybadger.notify(exception, context)
end
