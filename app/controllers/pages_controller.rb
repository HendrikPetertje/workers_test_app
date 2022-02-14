class PagesController < ApplicationController
  def index
    @name = params[:name]
    MessageJob.perform_later({ name: @name }) if @name.present?
  end
end
