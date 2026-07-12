class NodesController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:collaborator) }, except: [ :index, :show ]
  before_action -> { require_role!(:admin) }, only: [ :pause, :resume ]

  def index
    @pagy, @nodes = pagy(UptimeMonitor.ranked, limit: 15)
  end

  def new
    @node = UptimeMonitor.new(check_interval: 60, timeout: 30, request_type: "GET", down_threshold: 1)
  end

  def create
    @node = UptimeMonitor.new(node_params)
    if @node.save
      redirect_to nodes_path, notice: "Node created. First check in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @node = UptimeMonitor.find(params[:id])
  end

  def update
    @node = UptimeMonitor.find(params[:id])
    if @node.update(node_params)
      redirect_to node_path(@node), notice: "Node updated."
    else
      render :edit, status: :unprocessable_entity
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

  def assign_tag
    @node = UptimeMonitor.find(params[:id])
    tag = params[:tag].to_s.strip.presence
    return head(:bad_request) unless tag

    tags = Array(@node.tags)
    if tags.include?(tag)
      @node.update!(tags: tags - [ tag ])
    else
      @node.update!(tags: (tags + [ tag ]).uniq)
    end

    render turbo_stream: turbo_stream.update(helpers.dom_id(@node, :tags), partial: "nodes/tags", locals: { node: @node })
  end

  def pause
    @node = UptimeMonitor.find(params[:id])
    @node.update!(paused: true)

    ActionLog.log(
      action: :paused,
      record: @node,
      account: current_account,
      metadata: { name: @node.name, note: params[:note].presence }
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to node_path(@node), notice: "#{@node.name} paused." }
    end

    DashboardBroadcastService.call(updated_nodes: @node)
  end

  def resume
    @node = UptimeMonitor.find(params[:id])
    @node.update!(paused: false)

    ActionLog.log(
      action: :resumed,
      record: @node,
      account: current_account,
      metadata: { name: @node.name }
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to node_path(@node), notice: "#{@node.name} resumed." }
    end

    DashboardBroadcastService.call(updated_nodes: @node)
  end

  def toggle_public_listed
    @node = UptimeMonitor.find(params[:id])
    @node.update!(public_listed: !@node.public_listed)
    render partial: "nodes/public_listed_frame", locals: { node: @node }
  end

  private

  def node_params
    params.require(:uptime_monitor).permit(:name, :url, :check_interval, :timeout, :request_type, :expected_status, :request_body, :down_threshold, :tag_list, :public_listed, tags: [])
  end
end
