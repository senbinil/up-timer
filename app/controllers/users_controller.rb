class UsersController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:admin) }

  def index
    @users = Account.order(:email)
  end

  def update_role
    @user = Account.find(params[:id])

    if @user.id == current_account.id
      return redirect_to users_path, alert: "You cannot change your own role."
    end

    new_role = params[:role]
    old_role = @user.role

    if Account::ROLES.include?(new_role)
      @user.update!(role: new_role)
      ActionLog.log(action: :role_changed, record: @user, account: current_account,
                    metadata: { target: @user.email, old_role: old_role, new_role: new_role })
      redirect_to users_path, notice: "#{@user.email} is now #{new_role}."
    else
      redirect_to users_path, alert: "Invalid role."
    end
  end
end
