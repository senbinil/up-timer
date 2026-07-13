require "rails_helper"

RSpec.describe DbAdapter::Postgres do
  describe ".configure!" do
    before do
      allow(Rails.logger).to receive(:info)
    end

    it "logs that PostgreSQL is being used" do
      described_class.configure!
      expect(Rails.logger).to have_received(:info).with(/PostgreSQL/)
    end

    it "routes Solid Queue to primary database" do
      described_class.configure!
      expect(Rails.application.config.solid_queue.connects_to)
        .to eq({ database: { writing: :primary } })
    end

    it "routes Solid Cache to primary database" do
      described_class.configure!
      expect(Rails.application.config.solid_cache.connects_to)
        .to eq({ database: { writing: :primary } })
    end
  end
end
