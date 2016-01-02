class JobsController < ApplicationController
  protect_from_forgery except: [ :create ]

  def create
    delay = params[:delay].to_i
    if delay > 0
      job = TestJob.new(params[:random_string])
      job.enqueue wait: delay.seconds
    else
      TestJob.perform_later(params[:random_string])
    end

    render nothing: true, status: :ok
  end
end
