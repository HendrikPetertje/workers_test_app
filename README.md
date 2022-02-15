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
### Attempt 3: Resque
Time to try out a completely different framework then.
I noticed that a lot of the things we require in our project (like retrying,
scheduling and a web interface) were present as stand-alone plugins, but a lot
of these plugins haven't seen updates for 4-7 years, so I wasn't too hopeful from
the get go. I ended up installing the base system just to see if I could get
things up and running and I don't know, it almost works but:

- Jobs are lost on app down, there is some work going on trying to implement 
  RPOPLPUSH with Redis, but it relies on jobs timing out rather than connections
  being dropped for a longer time like RabbitMQ did with its unacked system. The
  entire functionality is still in development too
  https://github.com/resque/resque/pull/1788.
- There's a lot of own development required to actually make the retry logic
  respect waiting in some kind of Backoff system.

That said, the project does come with

- Scheduling
- CRON
- web interfaces and failure inspection
- Airbrake & Newrelic support
- some rudimentary form of retry

But given it doesn't actually fix the base issue we have with Sidekiq right now
this entire development path is going to be a no-go.
