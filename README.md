# Worker Test app

## what?
We're developing this app to test out different worker systems in one of our 
ongoing projects, this to replace Sidekiq (free) which raises issues for us by
forgetting about jobs when it crashes.

## requirements for the new solution:
- Doesn't loose stuff on unscheduled interrupts.
- Sits really close or works in tandem with Rails ActiveJob, so we stay in the walled garden of rails as much as possible and don't have to rewrite the entire app.
- Works with future versions of Rails.
- Needs to be able to retry jobs x times and have some kind of interface allowing us to re-schedule or inspect whats going on.
- schedule stuff

## How to test
- This demo app has a single pages controller which reads the "name" argument from
a request.
- A worker should be invoked with this name argument. called a NameWorker or
  something
- The worker process should start, wait 10 seconds and then Log out a success
  message.

- All of this should be created after 10 seconds when visiting
  http://localhost:3000/?name=foo.
- Add your worker starter to bin/hard_worker.
- Uncomment the worker in Procfile.dev.
- start the rails server with `bin/dev`
- when exiting `bin/dev` (or otherwise killing the worker using a SIGKILL) the
  job should be preserved, restarting the rails server + worker server should
  cause the job to be finished.
- optional: create an rspec test that tests everything.

## How to get started
We have a list of plugins we'd like to try out, a developer on the team can
pick one and then do a `git checkout -b [developer-name]-[framework-pick]` and
implement their worker system.

We'll compare and demo results when we finish :D

The different options:
- RabbitMQ & sneakers - Reserved by Peter :p
- Delayed job with delayed-job-web
- Resque, resque-web and resque-retry
- kafka (will be a pain to integrate on-prem, so maybe not)
- ActiveJob vanilla (with some kind of UI and retry logic)


## Starting the server:
bin/dev

## Killing the server (make sure ):
bin/rip

## Attempt report
### Attempt 2: Advanced Sneakers ActiveJob
Like attempt 1 there isn't really a need for a bin/rip script as foreman has
significantly less patience than the worker :p. just CTRL+C as soon as you have
loaded http://localhost:3000/?name=hello-world and you should be good!

That said, I'm really liking what I'm seeing here! There are so many advantages:
- It's fast!
- Jobs are sent in to the queue and returned from the queue, it all just works.
- Queue-names are respected. There can be multiple job types per queue too, so
  that's a win!
- Time-outs, re-queueing and anything that isn't the job itself is handled by
  the rabbitMQ server (more about the job life-cycle below).
- Failing jobs are retried with "Exponential Back-off" which means that on first
  failure rabbitMQ will delay the job with 3 seconds, then 30 and then up all
  the way till it's stuck in a "try once per 24 hours" cycle at which point we
  should start to act.
- Newrelic is natively supported (getting per-worker metrics) and so is our
  current project's backup error tracker (through Airbrake) and any extra error
  tracker or Newrelic custom-event we'd like to add.
- It's all "rip the powerplug"-safe! With queues persisted to disk, ackable
  messages in our apps, etc.
- It opens a path for increased communication between our project's admin portal
  and our app infrastructure (maybe, though we should probably only build infra
  for that when we actually need it ;)).
- It has a web interface (through rabbitMQ) and options to automate different
  things on the RabbitMQ side.
- There is [excellent documentation](https://blog.rabbitmq.com/posts/2020/08/deploying-rabbitmq-to-kubernetes-whats-involved/) 
  available for use with Kubernetes in situations where we don't have 
  access to "Amazon MQ for RabbitMQ". The important bit we need to be aware of
  is the "Erlang Cookie" and volumes.

The disadvantages however:
- The framework depends on a pet-project by "[Veeqo](https://www.veeqo.com)".
  It's starting to become more and more popular, but its downloaded only
  22.213 times. The Rails 7.0 compatible code is only available on Github right
  now. If we are to use this project then we'll need to make sure to make 
  forks of the following projects for the sake of not loosing access to them
  later on:
  - [advanced-sneakers-activejob](https://rubygems.org/gems/advanced-sneakers-activejob)
  - [bunny-publisher](https://rubygems.org/gems/bunny-publisher)
- No CRON scheduler to run tasks at specific times of the day. So we'll need to
  create a pod in our clusters that executes a persisted task using either:
  - https://github.com/jmettraux/rufus-scheduler
  - https://github.com/jjb/ruby-clock (easy integration with rails)
  - https://github.com/plashchynski/crono (over-engineered, it's more than we
    need)
- We have to depend on Bunny for increased reliability of our connection and the
  workers, but given that the adapter supports it that is not really a problem.
- We need to provision Amazon MQ rabbitMQ instances and deal with rabbit pods +
  volumes in our on-prem install.

A job Life-cycle:

- A job is created using Rails default `perform_later` logic.
- The job is posted to rabbitMQ a durable (persisted) RMQ exchange which pops
  the task on a queue. Ack-ing is enforced.
- The job is distributed to one of the connected workers channels using
  "round-robin".
- A rails worker picks the job from the queue with "manual Ack", the job is
  persisted in the queue as "unacked" by a connection and channel.
- When the worker finishes its work:
  - the worker publishes an "ack!" back to the queue
  - rabbitMQ marks the job as complete and removes it from the queue.
- When the worker fails:
  - The worker re-publishes the job to the "delayed" exchange 
    with a retry-counter and the desired time-out time.
  - RabbitMQ moves the message from the jobs queue, publishes it to the
    delayed-X queue (where X is the delay time) and unassigns it from the
    connection + channel.
  - The delayed-X queue automatically pushes the job back in to the worker
    queue when the task has been in the queue for X secodns persisting its
    retry and error headers. A worker can then pick it back up.
- When the worker dies or SIGKILLs:
  - RabbitMQ will detect that the connection is gone, expire the channels,
    remove the unacked status and make the job available for the next worker.
  - A new worker (or other live-worker) will attempt to re-do the task

It's super awesome, I'm absolutely going to demo this!
