class NodesController < ApplicationController
  layout "dashboard"
  before_action :authenticate

  def index
    @nodes = UptimeMonitor.all.order(created_at: :desc)
  end

  def new
    @node = UptimeMonitor.new(check_interval: 60, timeout: 30)
  end

  def create
    @node = UptimeMonitor.new(node_params)
    if @node.save
      redirect_to nodes_path, notice: "Node created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @node = UptimeMonitor.find(params[:id])
    @checks = @node.monitor_checks.order(checked_at: :desc).limit(50)
  end

  def destroy
    @node = UptimeMonitor.find(params[:id])
    @node.destroy
    redirect_to nodes_path, notice: "Node deleted."
  end

  private

  def authenticate
    rodauth.require_account
  end

  def node_params
    params.require(:uptime_monitor).permit(:name, :url, :check_interval, :timeout)
  end
end
