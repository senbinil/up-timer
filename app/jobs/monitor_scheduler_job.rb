class MonitorSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    UptimeMonitor.active.find_each do |monitor|
      next if monitor.check_interval.nil?
      last_check = monitor.monitor_checks.maximum(:checked_at)
      next if last_check && last_check > monitor.check_interval.seconds.ago

      MonitorCheckJob.perform_later(monitor.id)
    end
  end
end
