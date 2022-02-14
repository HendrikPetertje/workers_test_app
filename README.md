# Worker Test app

## what?
We're developing this app to test out different worker systems in one of our 
ongoing projects, this to replace Sidekiq (free) which raises issues for us by
forgetting about jobs when it crashes.

## requirements for the new solution:
- Doesn't loose stuff on unscheduled interrupts
- Sits really close or works in tandem with Rails ActiveJob, so we stay in the walled garden of rails as much as possible and don't have to rewrite the entire app
- Works with future versions of Rails
- Needs to be able to retry jobs x times and have some kind of interface allowing us to re-schedule or inspect whats going on
- schedule stuff

## How to test
- This demo app has a single pages controller which reads the "name" argument from
a request.
- A worker should be invoked with this name argument. called a NameWorker or
  something
- The worker process should start, wait 10 seconds and then Create a new file
  using:

```
File.open(Rails.root.join('tmp', "#{name}.txt"), "w") {}
```

- The file should be created after 10 seconds when visiting
  http://localhost:3000/?name=foo
- Add your worker starter to bin/hard_worker
- Uncomment the worker in Procfile.dev
- start the rails server with `bin/dev`
- when exiting `bin/dev` (or otherwise killing the worker using a SIGKILL) the
  job should be preserved, restarting the rails server + worker server should
  cause the job to be finished
- optional: create an rspec test that tests everything

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

## Killing the server:
bin/rip

## Attempt report
### Attempt 1: Sneakers

There is no need for any bin/rip scripts. the default job runs for 10 seconds
and default foreman has 4 seconds of patience, so no need to kill anything,
foreman already does it for us.

Sneakers works pretty nicely, it is fault tolerant, keeps jobs and uses
an ackable system, so all of this is pretty frickin' cool!

I did however run into some problems:

1: Shutting down workers by getting the main process SIGKILL-ed leaves
orphaned connections to rabbitMQ that aren't shut down. This plus
connection time-outs (workers that haven't gotten anything to do dying
silently after a while) and other problems is posing some troubles on it
all.

The solution for this seems to be to use Bunny to make connections for
us instead!

There are however some other minor issues:

1. queue_as is not respected, so everything is put on the same queue, so
   this will not scale well with multiple jobs. (unless you are using
   workers instead of active_job)
2. "retry" works on native "workers" but not in active-job, so a failed
   job will fail and then never be sent or read from the retry-queue.
3. There is no support for delayed jobs, we have a bunch of those in our
   project.
4 there is no documentation at all for ActiveJob.
5. https://github.com/jondot/sneakers/pull/446 retry is broken, pull
   request has been open since forever.

Next thing to try out [advanced-sneakers-activejob](https://github.com/veeqo/advanced-sneakers-activejob)
