class NodeDependenciesController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:admin) }
  before_action :set_node

  def index
    @dependencies = @node.dependencies.includes(:monitor_checks)
    @dependents = @node.dependents.includes(:monitor_checks)
  end

  def available
    @nodes = @node.available_dependencies.ranked
    render partial: "available_list", locals: { node: @node, nodes: @nodes }
  end

  def create
    dependency = UptimeMonitor.find(params[:dependency_id])

    if @node.dependencies.include?(dependency)
      redirect_to node_dependencies_path(@node), alert: "Already a dependency."
      return
    end

    if @node.id == dependency.id
      redirect_to node_dependencies_path(@node), alert: "A node cannot depend on itself."
      return
    end

    if circular_dependency?(dependency)
      redirect_to node_dependencies_path(@node), alert: "Cannot create a circular dependency."
      return
    end

    @node.monitor_dependencies.create!(dependency: dependency)
    redirect_to node_dependencies_path(@node), notice: "Dependency added."
  end

  def destroy
    @node.monitor_dependencies.find_by(dependency_id: params[:id])&.destroy!
    redirect_to node_dependencies_path(@node), notice: "Dependency removed."
  rescue ActiveRecord::RecordNotFound
    redirect_to node_dependencies_path(@node), alert: "Dependency not found."
  end

  private

  def set_node
    @node = UptimeMonitor.find(params[:node_id])
  end

  def circular_dependency?(dependency)
    # Check if adding this dependency would create a cycle:
    # the dependency already depends on this node (directly or transitively)
    visited = Set.new
    to_check = [ dependency ]

    while to_check.any?
      current = to_check.shift
      next if visited.include?(current.id)
      visited.add(current.id)

      return true if current.id == @node.id

      to_check.concat(current.dependencies.to_a)
    end

    false
  end
end
