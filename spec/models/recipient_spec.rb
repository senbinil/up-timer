require "rails_helper"

RSpec.describe Recipient, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active recipients" do
        active = create(:recipient, active: true)
        _inactive = create(:recipient, active: false)

        expect(Recipient.active).to contain_exactly(active)
      end
    end

    describe ".ordered" do
      it "orders by name" do
        b = create(:recipient, name: "B")
        a = create(:recipient, name: "A")

        expect(Recipient.ordered).to eq([ a, b ])
      end
    end
  end

  describe "before_validation :set_default_name on create" do
    it "sets name from email prefix when name is blank" do
      recipient = create(:recipient, name: "", email: "testuser@example.com")
      expect(recipient.name).to eq("testuser")
    end

    it "does not override an explicit name" do
      recipient = create(:recipient, name: "Custom Name", email: "test@example.com")
      expect(recipient.name).to eq("Custom Name")
    end
  end

  describe "email format" do
    it "is valid with a proper email" do
      recipient = build(:recipient, email: "valid@example.com")
      expect(recipient).to be_valid
    end
  end
end
