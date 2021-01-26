class RandomStringsController < ApplicationController

  # GET /random_strings
  # GET /random_strings.json
  def index
    @random_strings = RandomString.all
  end

  def new
    @random_string = RandomString.new
  end

  # POST /random_strings
  # POST /random_strings.json
  def create
    @random_string = RandomString.new(permitted_params)
    @random_string.save!
    
    respond_to do |format|
      format.json { render :json => @random_string }
      format.html { redirect_to random_string_path(@random_string.id) }
    end
  end

  def show
    @random_string = RandomString.find(params[:id])
  end

  def edit
    @random_string = RandomString.find(params[:id])
  end

  def update
    @random_string = RandomString.find(params[:id])
    @random_string.update!(permitted_params)
    
    respond_to do |format|
      format.json { render :json => @random_string }
      format.html { redirect_to random_string_path(@random_string.id) }
    end
  end

  def destroy
    @random_string = RandomString.find_by_random_string(params[:id])
    @random_string.destroy!
        
    respond_to do |format|
      format.json { render :json => @random_string }
      format.html { redirect_to random_strings_path }
    end
  end

  private

  def permitted_params
    params.require(:random_string).permit(:random_string)
  end

end
