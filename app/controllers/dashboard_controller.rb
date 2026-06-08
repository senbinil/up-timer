class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
    @chart_data = generate_chart_data
    @nodes = UptimeMonitor.all.order(created_at: :desc)
    @services = @nodes.first(3)
  end

  private

  def generate_chart_data
    24.times.map { |i| [ "Day #{i + 1}", rand(60..100) ] }.to_h
  end
  helper_method :random_chart_data, :db_chart_data

  def random_chart_data
    @chart_data ||= generate_chart_data
  end

  def db_chart_data
    24.times.map { |i| [ "Day #{i + 1}", [ 15, 20 ].include?(i) ? rand(30..50) : rand(70..100) ] }.to_h
  end

  def authenticate
    rodauth.require_account
  end
end
