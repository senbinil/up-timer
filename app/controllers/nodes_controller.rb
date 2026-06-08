class NodesController < ApplicationController
  layout "dashboard"
  before_action :authenticate

  def index
    @pagy, @nodes = pagy(UptimeMonitor.ranked, limit: 15)
  end

  def new
    @node = UptimeMonitor.new(check_interval: 60, timeout: 30)
  end

  def create
    @node = UptimeMonitor.new(node_params)
    if @node.save
      redirect_to nodes_path, notice: "Node created. First check in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @node = UptimeMonitor.find(params[:id])
    limit = (params[:per_page] || 25).to_i.clamp(10, 100)
    @pagy, @checks = pagy(@node.monitor_checks.order(checked_at: :desc), limit: limit)
  end

  def destroy
    @node = UptimeMonitor.find(params[:id])
    @node.destroy
    redirect_to nodes_path, notice: "Node deleted."
  end

  def move_up
    node = UptimeMonitor.find(params[:id])
    node.update!(position: node.position + 1)
    redirect_to nodes_path
  end

  def move_down
    node = UptimeMonitor.find(params[:id])
    node.update!(position: node.position - 1)
    redirect_to nodes_path
  end

  private

  def authenticate
    rodauth.require_account
  end

  def node_params
    params.require(:uptime_monitor).permit(:name, :url, :check_interval, :timeout)
  end
end
