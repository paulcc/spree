class UserSessionsController < Spree::BaseController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
    
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    success = @user_session.save 
    respond_to do |format|
      format.html {                                
        if success 
          ## disable ## flash[:notice] = t("logged_in_successfully")
          redirect_back_or_default products_path
        else
          flash.now[:error] = t("login_failed")
          @user = User.new :email => params[:user_session][:email]
          render :template => 'users/new'
        end
      }
      format.js {
        render :js => success.to_json
      }
    end    
  end

  def destroy
    current_user_session.destroy
    reset_session                                      # useful for clearing things
    flash[:notice] = t("you_have_been_logged_out")
    redirect_to products_path
  end
end
