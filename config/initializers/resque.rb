Resque.redis = ENV.fetch('REDIS_URI', 'localhost:6379')
Resque.redis.namespace = 'resque'
