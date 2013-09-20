class UsersController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :js

  def index
    @users = User.search_for(current_user, params).asc(:username).page(params[:page]).per(15)
    respond_with @users
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.is_active = true

    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
      Cycle.create ({:title => 'NO_CYCLE', :description =>"NO_CYCLE_DESC",:author => @user})
    else
      render action: "new"
    end
  end

  def update
    begin
      @user = User.find(params[:id])
      if @user.update_attributes(params[:user])
        redirect_to user_profile_path, :notice => t('USER_INFO_UPDATE_SUCCESS')
      else
        redirect_to edit_profile_path(@user), :alert => t('USER_INFO_CAN_NOT_BE_UPDATED')
      end
    rescue Exception => e
      redirect_to edit_profile_path(@user), :alert => "#{t('USER_INFO_CAN_NOT_BE_UPDATED')}: #{e.message}"
    end
  end

  def destroy
  end

  def edit
    @user = User.find(params[:id])
  end

  def change_role
    authorize! :change_role, User
    @user = User.find(params[:id])
    @user.change_role(params[:role])
    redirect_to users_path, :notice => t(:USER_ROLE_CHANGED)
  end

end
