module ApplicationHelper
  def severity_chip_class(severity)
    case severity
    when "critical" then "chip chip-error"
    when "warning" then "chip chip-warning"
    else "chip chip-success"
    end
  end
end
