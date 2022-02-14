class MessageJob < ApplicationJob
  queue_as :rails_default

  def perform(args)
    puts args
    puts "''''''''''''"
    puts "''''''''''''"
    puts "''''''''''''"
    puts "''''''''''''"
    puts 'Going to sleep'
    sleep 10
    puts 'DONE!'
    Sneakers.logger.info 'Hello World!'
  end
end
