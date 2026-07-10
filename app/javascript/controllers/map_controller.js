import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="map"
export default class extends Controller {
  static values = { nodes: Array };
  static targets = ["container"];

  connect() {
    this._initMap();
  }

  disconnect() {
    this._removeMap();
  }

  _removeMap() {
    if (this._mapInstance) {
      this._mapInstance.remove();
      this._mapInstance = null;
    }
  }

  _initMap() {
    const nodes = this.nodesValue;
    if (!nodes.length) return;

    const bounds = [];
    const markers = [];

    for (const node of nodes) {
      if (!node.latitude || !node.longitude) continue;

      const latlng = [node.latitude, node.longitude];
      bounds.push(latlng);

      const color = this._statusColor(node.status);
      const icon = this._pinIcon(color);
      const popup = this._popupContent(node);

      const marker = L.marker(latlng, { icon })
        .addTo(this._map)
        .bindPopup(popup)
        .bindTooltip(node.name, {
          direction: "top",
          offset: [0, -32],
          permanent: true,
          className: "node-marker-tooltip",
        });

      markers.push(marker);
    }

    if (!bounds.length) {
      this.element.textContent = "No location data available.";
      return;
    }

    // Fit map to markers with padding, cap at continent level
    this._map.fitBounds(bounds, { padding: [40, 40], maxZoom: 4 });
  }

  get _map() {
    if (!this._mapInstance) {
      this._mapInstance = L.map(this.element, {
        zoomControl: true,
        attributionControl: false,
      });

      const dark = document.documentElement.classList.contains("dark");
      const tileUrl = dark
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

      L.tileLayer(tileUrl, {
        maxZoom: 19,
      }).addTo(this._mapInstance);

      // Invalidate after a short delay so the card container is laid out
      requestAnimationFrame(() => this._mapInstance.invalidateSize());
    }
    return this._mapInstance;
  }

  set _map(value) {
    this._mapInstance = value;
  }

  _statusColor(status) {
    if (status === "up") return "#22c55e";
    if (status === "down") return "#ef4444";
    if (status === "paused") return "#f59e0b";
    return "#64748b"; // unknown
  }

  _pinIcon(color) {
    const svg = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36" width="24" height="36">
        <path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 24 12 24s12-15 12-24C24 5.4 18.6 0 12 0z" fill="${color}"/>
        <circle cx="12" cy="12" r="4" fill="#fff"/>
      </svg>
    `;

    return L.divIcon({
      html: svg,
      className: "",
      iconSize: [24, 36],
      iconAnchor: [12, 36],
      popupAnchor: [0, -36],
    });
  }

  _popupContent(node) {
    const statusLabel =
      node.paused
        ? "Paused"
        : node.status === "up"
          ? "Up"
          : node.status === "down"
            ? "Down"
            : "Unknown";

    const statusColor =
      node.paused
        ? "#f59e0b"
        : node.status === "up"
          ? "#22c55e"
          : node.status === "down"
            ? "#ef4444"
            : "#64748b";

    return `
      <div style="font-family: Inter, sans-serif; font-size: 13px; line-height: 1.4; min-width: 140px;">
        <strong style="font-size: 14px;">${this._escapeHtml(node.name)}</strong>
        <br/>
        <span style="color: #64748b; font-family: 'JetBrains Mono', monospace; font-size: 11px;">${this._escapeHtml(node.url)}</span>
        <br/>
        <span style="display: inline-block; margin-top: 4px; padding: 1px 8px; border-radius: 999px; font-size: 10px; font-weight: 600; font-family: 'JetBrains Mono', monospace; text-transform: uppercase; letter-spacing: 0.05em; color: #fff; background-color: ${statusColor};">${statusLabel}</span>
        ${node.path ? `<br/><a href="${node.path}" style="font-size: 11px; color: #2563eb; margin-top: 4px; display: inline-block;">View details →</a>` : ""}
      </div>
    `;
  }

  _escapeHtml(str) {
    if (!str) return "";
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }
}
