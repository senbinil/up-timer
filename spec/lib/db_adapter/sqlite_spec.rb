require "rails_helper"

RSpec.describe DbAdapter::Sqlite do
  describe ".configure!" do
    before do
      allow(Rails.logger).to receive(:info)
    end

    it "logs that SQLite is being used" do
      described_class.configure!
      expect(Rails.logger).to have_received(:info).with(/SQLite/)
    end

    it "does not modify Solid Queue config" do
      expect { described_class.configure! }
        .not_to(change { Rails.application.config.solid_queue.connects_to })
    end

    it "does not modify Solid Cache config" do
      expect { described_class.configure! }
        .not_to(change { Rails.application.config.solid_cache.connects_to })
    end
  end
end
