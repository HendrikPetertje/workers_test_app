class PagesController < ApplicationController
  def index
    @name = params[:name]
    MessageJob.perform_later({ name: @name }) if @name.present?

    # Delay jobs example.
    # warning: delayed jobs will create a new RabbitMQ queue that re-publishes messages to the delayed exchange on complete
    # So create them with care ;)
    # MessageJob.set(wait: 10.seconds).perform_later({ name: @name }) if @name.present?
  end
end
