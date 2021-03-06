#encoding: utf-8
class CyclesController < ApplicationController

  before_filter :authenticate_user!, :except => [:show]
  load_and_authorize_resource :except => [:index, :show]

  include Concerns::BulkOperationable

  bulk_actions :delete, :tag

  respond_to :html, :js

  def index
  end

  def show
    @cycle = Cycle.find(params[:id])
    @comments = @cycle.comments.page(params[:page]).per(25)
    @articles = @cycle.ordered_articles.includes(:author).page(params[:articles_page]).per(12)

    respond_with @comments
  end

  def new
    @cycle = Cycle.new
  end

  def create
    @cycle = Cycle.new(cycle_params)
    @cycle.author = current_user

    if @cycle.save
      redirect_to cycles_office_path(scope:'current_user'), notice: t(:CYCLE_CREATE_SUCCESS)
    else
      render action: "new"
    end
  end

  def update
    @cycle = Cycle.find(params[:id])

    if @cycle.system?
      redirect_to cycles_office_path(scope:'current_user'), alert: t('CAN_NOT_EDIT_SYSTEM_CYCLE')
      return
    end

    if @cycle.update_attributes(cycle_params)
      redirect_to cycles_office_path(scope:'current_user'), notice: t(:CYCLE_UPDATE_SUCCESS)
    else
      render action: "edit"
    end
  end

  def destroy
    @cycle = Cycle.find(params[:id])

    message = t :UNABLE_TO_DELETE_CYCLE
    begin
      unless @cycle.destroy
        redirect_to @cycle, alert: message + @cycle.errors.full_messages.join(', ')
        return
      end
    rescue => e
      redirect_to @cycle, alert: message + e.message
      return
    end
    redirect_to cycles_office_path(scope:'current_user'), notice: t(:CYCLE_REMOVE_SUCCESS)
  end

  def edit
    @cycle = Cycle.find(params[:id])
    if @cycle.system?
      redirect_to cycles_office_path(scope:'current_user'), alert: t('CAN_NOT_EDIT_SYSTEM_CYCLE')
      return
    end
  end

  private

  def cycle_params
    params.require(:cycle).permit(:title, :logo, :description, :tag_list)
  end

end
