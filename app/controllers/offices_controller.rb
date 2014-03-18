class OfficesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :scope, except: [:non_approved,:non_approved_content]
  include Concerns::BulkOperationable

  bulk_actions :delete, :tag

  respond_to :html, :js, :json

  # TODO: Move it to model
  def show
    @last_pages = []

    elements = Impression.where(user_id: current_user._id).order_by([:created_at, :desc])
    elements.each do |element|
      break if @last_pages.size >= 10
      checking = element.impressionable_type.constantize.find(element.impressionable_id)
      unless checking == @last_pages.last
        @last_pages << checking
      end
    end
  end

  def articles
    params[:sort_by] ||= 'created_at'
    params[:direction] ||= 'desc'
    if params[:unprocessed]
      scope = Article.unprocessed
    else
      scope = Article.unscoped
    end
    @articles = scope.search_for(current_user, params).order_by(params[:sort_by].to_sym => params[:direction].to_sym).page(params[:page]).per(15)

    respond_with @articles
  end

  def cycles
    @cycles = Cycle.search_for(current_user, params).page(params[:page]).per(15)
    respond_with @cycles
  end

  def non_approved
    @articles = Article.non_approved(current_user, params).page(params[:page]).per(15)
    authorize! :approve, Article
    respond_with @articles
  end

  def galleries
    @galleries = Gallery.search_for(current_user,params).page(params[:page]).per(10)
    respond_with @galleries
  end

  def non_approved_content
    @contents = Content::BaseContent.non_approved(current_user, params).page(params[:page])
    authorize! :approve, Content::BaseContent
    respond_with @contents
  end

  def assign_badges_show
    @users = User.random
    @badges = Merit::Badge.all
    puts @users.blank?, @badges.blank?
  end

  def assign_badges_update

  end

  private

  def scope
    if params[:scope].nil?
      params[:scope] = 'current_user'
    end
  end
end