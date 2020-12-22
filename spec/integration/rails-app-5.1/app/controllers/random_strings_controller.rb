class RandomStringsController < ApplicationController

  # GET /random_strings
  # GET /random_strings.json
  def index
    @random_strings = RandomString.all
  end

  # POST /random_strings
  # POST /random_strings.json
  def create
    @random_string = RandomString.new(random_string: params[:random_string])
    @random_string.save!
    render nothing: true, status: :ok
  end

  def destroy
    @random_string = RandomString.find_by_random_string(params[:id])
    @random_string.destroy
    render nothing: true, status: :ok
  end
end
