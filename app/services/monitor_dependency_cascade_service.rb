class MonitorDependencyCascadeService
  def self.cascade_down(monitor)
    new(monitor).cascade_down
  end

  def self.cascade_recovery(monitor)
    new(monitor).cascade_recovery
  end

  def initialize(monitor)
    @monitor = monitor
  end

  def cascade_down
    @monitor.dependents.active.each do |dependent|
      dependent.update!(status: "down", dependency_affected: true)
      dependent.incidents.create!(started_at: Time.current)
      ActionLog.log(
        action: :dependency_down,
        record: dependent,
        metadata: { parent_id: @monitor.id, parent_name: @monitor.name }
      )
    end
  end

  def cascade_recovery
    @monitor.dependents.each do |dependent|
      other_parents_down = dependent.dependencies.where(status: "down").where.not(id: @monitor.id).exists?
      next if other_parents_down

      dependent.update!(dependency_affected: false)
      next if dependent.monitor_checks.order(checked_at: :desc).pick(:status) == "down"

      dependent.update!(status: "up")
      dependent.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)

      ActionLog.log(
        action: :dependency_up,
        record: dependent,
        metadata: { parent_id: @monitor.id, parent_name: @monitor.name }
      )
    end
  end
end
