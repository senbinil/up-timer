class UsersController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:admin) }

  def index
    @users = Account.order(:email)
  end

  def update_role
    @user = Account.find(params[:id])
    new_role = params[:role]

    if Account::ROLES.include?(new_role)
      @user.update!(role: new_role)
      redirect_to users_path, notice: "#{@user.email} is now #{new_role}."
    else
      redirect_to users_path, alert: "Invalid role."
    end
  end
end
