module ApplicationHelper
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

  def alert_chart_data(heatmap)
    [
      {
        name: "Critical",
        data: heatmap.map { |d| [ d[:date].strftime("%b %d"), d[:critical] ] }.to_h,
        color: "#ba1a1a"
      },
      {
        name: "Warning",
        data: heatmap.map { |d| [ d[:date].strftime("%b %d"), d[:warning] ] }.to_h,
        color: "#8c5000"
      },
      {
        name: "Info",
        data: heatmap.map { |d| [ d[:date].strftime("%b %d"), d[:info] ] }.to_h,
        color: "#2563eb"
      }
    ]
  end

end
