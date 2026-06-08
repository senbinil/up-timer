module ApplicationHelper
  include Pagy::Frontend
  def severity_chip_class(severity)
    case severity
    when "critical" then "chip chip-error"
    when "warning" then "chip chip-warning"
    else "chip chip-success"
    end
  end

  def lucide_icon(name, **options)
    size = options.delete(:size) || 16
    classes = options.delete(:class) || ""
    tag.i data: { lucide: name }, class: "lucide-icon inline-block #{classes}", style: "width: #{size}px; height: #{size}px"
  end
end
