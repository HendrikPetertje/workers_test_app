class MessageJob < ApplicationJob
  queue_as :default

  def perform(args)
    Sneakers.logger.info '------- ActiveJob job ------'
    puts args
    Sneakers.logger.info 'sleeping for 10'
    sleep 10
    Sneakers.logger.info '------- Job success! -------'
  end
end
