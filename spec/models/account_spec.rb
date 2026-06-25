require "rails_helper"

RSpec.describe Account, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:user_preference).dependent(:destroy) }
    it { is_expected.to have_many(:alerts).dependent(:nullify) }
    it { is_expected.to have_many(:resolved_alerts).class_name("Alert").dependent(:nullify) }
    it { is_expected.to have_many(:action_logs).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:role).in_array(Account::ROLES) }
  end

  describe "enums" do
    it "defines status enum with unverified, verified, closed" do
      expect(Account.statuses).to eq({ "unverified" => 1, "verified" => 2, "closed" => 3 })
    end
  end

  describe "callbacks" do
    describe "before_create :set_status_token" do
      it "sets a status_token on create" do
        account = create(:account)
        expect(account.status_token).to be_present
      end
    end

    describe "after_create :build_default_preference" do
      it "creates a default user_preference after create" do
        account = create(:account)
        expect(account.user_preference).to be_persisted
        expect(account.user_preference.dashboard_limit).to eq(3)
      end
    end
  end

  describe "#admin?" do
    it "returns true when role is admin" do
      account = build(:account, role: "admin")
      expect(account).to be_admin
    end

    it "returns false when role is not admin" do
      account = build(:account, role: "viewer")
      expect(account).not_to be_admin
    end
  end

  describe "#collaborator?" do
    it "returns true for admin role" do
      account = build(:account, role: "admin")
      expect(account).to be_collaborator
    end

    it "returns true for collaborator role" do
      account = build(:account, role: "collaborator")
      expect(account).to be_collaborator
    end

    it "returns false for viewer role" do
      account = build(:account, role: "viewer")
      expect(account).not_to be_collaborator
    end
  end

  describe "#preference" do
    it "returns existing user_preference" do
      account = create(:account)
      pref = account.user_preference
      expect(account.preference).to eq(pref)
    end

    it "creates a preference if none exists" do
      account = create(:account)
      account.user_preference.destroy!
      account.reload

      new_pref = account.preference
      expect(new_pref).to be_persisted
      expect(new_pref.dashboard_limit).to eq(3)
    end
  end

  describe "constants" do
    it "defines ROLES" do
      expect(Account::ROLES).to contain_exactly("viewer", "collaborator", "admin")
    end
  end
end
