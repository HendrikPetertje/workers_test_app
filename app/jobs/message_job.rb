class MessageJob < ApplicationJob
  queue_as :default

  def perform(args)
    puts '------- ActiveJob job ------'
    puts args
    puts 'sleeping for 10'
    sleep 10
    puts '------- Job success! -------'
  end
end
