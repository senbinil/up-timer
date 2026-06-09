class AlertsController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action :set_alert, only: [ :show, :edit, :update, :destroy, :resolve ]

  def index
    @pagy, @alerts = pagy(Alert.recent, limit: 15)
    @heatmap = alert_heatmap
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

  def resolve
    @alert.update!(resolved: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to alerts_path, notice: "Alert resolved." }
    end
  end

  private

  def alert_heatmap
    29.downto(0).map do |days_ago|
      date = days_ago.days.ago.to_date
      day_alerts = Alert.where(created_at: date.all_day)
      {
        date: date,
        count: day_alerts.count,
        critical: day_alerts.where(severity: "critical").count,
        warning: day_alerts.where(severity: "warning").count,
        info: day_alerts.where(severity: "info").count
      }
    end
  end

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
