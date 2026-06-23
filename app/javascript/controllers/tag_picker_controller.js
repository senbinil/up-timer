import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static values = { nodeId: String, tags: Array, allTags: Array };

    connect() {
        this.dropdown = null;
        this._boundClose = this._closeIfOutside.bind(this);
        document.addEventListener("click", this._boundClose);
    }

    disconnect() {
        document.removeEventListener("click", this._boundClose);
        this._removeDropdown();
    }

    toggle(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.dropdown) {
            this._removeDropdown();
            return;
        }
        this._showPicker();
    }

    _showPicker() {
        const currentTags = this.tagsValue || [];
        const availableTags = this.allTagsValue || [];

        const dropdown = document.createElement("div");
        dropdown.className =
            "absolute z-50 bg-white border border-[#e2e8f0] rounded-default shadow-lg p-2 min-w-[160px]";
        const rect = this.element.getBoundingClientRect();
        dropdown.style.top = rect.bottom + 4 + "px";
        dropdown.style.left = rect.left + "px";
        dropdown.style.position = "fixed";
        dropdown.addEventListener("click", (e) => e.stopPropagation());

        availableTags.forEach((tag) => {
            const row = document.createElement("div");
            const isActive = currentTags.includes(tag);
            row.className =
                "flex items-center gap-2 w-full px-2 py-1 text-xs font-mono hover:bg-surface-container-low rounded-sm transition-colors cursor-pointer select-none";
            row.innerHTML = `<span class="${isActive ? "text-success" : "text-slate-400"}">${isActive ? "●" : "○"}</span><span>${this._h(tag)}</span>`;
            row.addEventListener("mousedown", (e) => {
                e.preventDefault();
                e.stopPropagation();
                this._assignTag(tag);
            });
            dropdown.appendChild(row);
        });

        const inputRow = document.createElement("div");
        inputRow.className =
            "flex items-center gap-1 mt-2 pt-2 border-t border-divider";
        const input = document.createElement("input");
        input.type = "text";
        input.placeholder = "New tag...";
        input.className =
            "flex-1 text-xs font-mono px-2 py-1 border border-[#e2e8f0] rounded-sm outline-none focus:border-primary-container";
        input.addEventListener("mousedown", (e) => e.stopPropagation());
        const addBtn = document.createElement("div");
        addBtn.className =
            "text-[10px] text-primary-container font-mono px-2 py-1 cursor-pointer select-none";
        addBtn.textContent = "Add";
        addBtn.addEventListener("mousedown", (e) => {
            e.preventDefault();
            e.stopPropagation();
            const v = input.value.trim();
            if (v) this._assignTag(v);
        });
        inputRow.appendChild(input);
        inputRow.appendChild(addBtn);
        dropdown.appendChild(inputRow);

        this._removeDropdown();
        document.body.appendChild(dropdown);
        this.dropdown = dropdown;
    }

    async _assignTag(tag) {
        this._removeDropdown();
        const csrf = document.querySelector('meta[name="csrf-token"]')?.content;
        try {
            const resp = await fetch(`/nodes/${this.nodeIdValue}/assign_tag`, {
                method: "PATCH",
                headers: {
                    "Content-Type": "application/json",
                    Accept: "text/vnd.turbo-stream.html",
                    "X-CSRF-Token": csrf,
                },
                body: JSON.stringify({ tag }),
            });
            const html = await resp.text();
            Turbo.renderStreamMessage(html);
        } catch {}
    }

    _removeDropdown() {
        if (this.dropdown) {
            this.dropdown.remove();
            this.dropdown = null;
        }
    }

    _closeIfOutside(event) {
        if (
            this.dropdown &&
            !this.dropdown.contains(event.target) &&
            event.target !== this.element
        ) {
            this._removeDropdown();
        }
    }

    _h(text) {
        const d = document.createElement("div");
        d.textContent = text;
        return d.innerHTML;
    }
}
