require 'bunny'
require 'sneakers'
require 'sneakers/handlers/maxretry'

Sneakers.configure(
  heartbeat: 2,
  connection: Bunny.new(ENV.fetch('SNEAKERS_URI', 'amqp://guest:guest@localhost:5672')),
  vhost: '/',
  exchange: 'test-app',
  exchange_type: :fanout,

  prefetch: ENV.fetch('SNEAKERS_THREADS', '4').to_i, # Grab 10 jobs together. Better speed.
  threads: ENV.fetch('SNEAKERS_THREADS', '4').to_i,  # Threadpool size (good to match prefetch)
  workers: ENV.fetch('SNEAKERS_WORKERS', '1').to_i,  # Number of workers, preferably one with bunny
  env: ENV['RACK_ENV'],                              # Environment
  # timeout_job_after: 20,                           # Maximal seconds to wait for job
  durable: true,                                     # Is queue durable?
  ack: true,                                         # Must we acknowledge? (reserve jobs and release on failure)
  hooks: {},                                         # before_fork/after_fork hooks
  start_worker_delay: 4,                             # Delay between thread startup

  retry_timeout: 5 * 1000, # 5 minutes
  retry_max_times: 6,
  handler: Sneakers::Handlers::Maxretry
)

Sneakers.logger.level = Logger::INFO
# Sneakers.logger = Rails.logger
