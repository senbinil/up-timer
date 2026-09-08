module LoadableFleetStats
  extend ActiveSupport::Concern

  private

  def load_fleet_stats(scope: nil)
    @stats = FleetStatsService.call(scope)
  end
end
