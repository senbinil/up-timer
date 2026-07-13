require "rails_helper"

RSpec.describe DbAdapter do
  describe ".configure!" do
    before do
      allow(Rails.logger).to receive(:info)
    end

    context "with DB_PROVIDER=postgres" do
      before do
        stub_const("ENV", ENV.to_hash.merge("DB_PROVIDER" => "postgres"))
      end

      it "calls Postgres adapter" do
        expect(DbAdapter::Postgres).to receive(:configure!)
        described_class.configure!
      end
    end

    context "with DB_PROVIDER=sqlite" do
      before do
        stub_const("ENV", ENV.to_hash.merge("DB_PROVIDER" => "sqlite"))
      end

      it "calls Sqlite adapter" do
        expect(DbAdapter::Sqlite).to receive(:configure!)
        described_class.configure!
      end
    end

    context "with DB_PROVIDER unset" do
      before do
        stub_const("ENV", ENV.to_hash.merge("DB_PROVIDER" => nil))
      end

      it "calls Sqlite adapter as default" do
        expect(DbAdapter::Sqlite).to receive(:configure!)
        described_class.configure!
      end
    end
  end
end
