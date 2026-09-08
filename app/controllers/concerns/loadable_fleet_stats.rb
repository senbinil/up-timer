module LoadableFleetStats
  extend ActiveSupport::Concern

  included do
    before_action :load_fleet_stats, only: [ :index ]
  end

  private

  def load_fleet_stats
    @stats = FleetStatsService.call
  end
end
