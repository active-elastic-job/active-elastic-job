class JobsController < ApplicationController
  protect_from_forgery except: [ :create ]

  def create
    TestJob.perform_later(params[:random_string])

    render nothing: true, status: :ok
  end
end
