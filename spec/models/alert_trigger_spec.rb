require "rails_helper"

RSpec.describe AlertTrigger, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:severity).in_array(%w[critical warning info maintenance]) }
  end

  describe "scopes" do
    describe ".ordered" do
      it "orders by name" do
        b = create(:alert_trigger, name: "B")
        a = create(:alert_trigger, name: "A")

        expect(AlertTrigger.ordered).to eq([ a, b ])
      end
    end
  end

  describe "#last_action_log" do
    it "returns the most recent action log for this trigger" do
      trigger = create(:alert_trigger)
      log1 = ActionLog.log(action: "toggled", record: trigger, metadata: { active: true })
      log2 = ActionLog.log(action: "toggled", record: trigger, metadata: { active: false })

      expect(trigger.last_action_log).to eq(log2)
    end

    it "returns nil when no action logs exist" do
      trigger = create(:alert_trigger)
      expect(trigger.last_action_log).to be_nil
    end
  end
end
