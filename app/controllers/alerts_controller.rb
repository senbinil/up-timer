class AlertsController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action :set_alert, only: [ :show, :edit, :update, :destroy ]

  def index
    @pagy, @alerts = pagy(Alert.recent, limit: 15)
  end

  def show
  end

  def new
    @alert = Alert.new(severity: "info")
    @monitors = UptimeMonitor.all.order(:name)
  end

  def create
    @alert = Alert.new(alert_params)
    if @alert.save
      redirect_to alerts_path, notice: "Alert created."
    else
      @monitors = UptimeMonitor.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monitors = UptimeMonitor.all.order(:name)
  end

  def update
    if @alert.update(alert_params)
      redirect_to alerts_path, notice: "Alert updated."
    else
      @monitors = UptimeMonitor.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @alert.destroy
    redirect_to alerts_path, notice: "Alert deleted."
  end

  private

  def authenticate
    rodauth.require_account
  end

  def set_alert
    @alert = Alert.find(params[:id])
  end

  def alert_params
    params.require(:alert).permit(:severity, :message, :monitor_id, :resolved)
  end
end
