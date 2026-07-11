class AlertsController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action :set_alert, only: [ :show, :edit, :update, :destroy, :resolve ]
  before_action -> { require_role!(:collaborator) }, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    @pagy, @alerts = pagy(Alert.recent, limit: 15)
    @heatmap = Alert.heatmap
  end

  def show
  end

  def new
    @alert = Alert.new(severity: "info")
    @monitors = UptimeMonitor.all.order(:name)
    @triggers = AlertTrigger.ordered
  end

  def create
    @alert = Alert.new(alert_params)
    @alert.account = current_account
    if @alert.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, alerts_path) }
        format.html { redirect_to alerts_path, notice: "Alert created." }
      end
    else
      @monitors = UptimeMonitor.all.order(:name)
      @triggers = AlertTrigger.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monitors = UptimeMonitor.all.order(:name)
    @triggers = AlertTrigger.ordered
  end

  def update
    if @alert.update(alert_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, alerts_path) }
        format.html { redirect_to alerts_path, notice: "Alert updated." }
      end
    else
      @monitors = UptimeMonitor.all.order(:name)
      @triggers = AlertTrigger.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @alert.destroy
    redirect_to alerts_path, notice: "Alert deleted."
  end

  def resolve
    @alert.update!(resolved: true, resolved_by: current_account)
    ActionLog.log(action: :resolved, record: @alert, account: current_account,
                  metadata: { name: @alert.monitor&.name, severity: @alert.severity })
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to alerts_path, notice: "Alert resolved." }
    end
  end

  private

  def set_alert
    @alert = Alert.find(params[:id])
  end

  def alert_params
    params.require(:alert).permit(:severity, :message, :monitor_id, :resolved, :alert_trigger_id)
  end
end
