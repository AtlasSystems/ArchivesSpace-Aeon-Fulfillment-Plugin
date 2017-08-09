class RequestsController < ApplicationController

  # send a request
  def make_request
    redirect_to 'https://www.google.com'
  end
end