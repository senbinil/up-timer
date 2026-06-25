require "rails_helper"

RSpec.describe Incident, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:monitor).class_name("UptimeMonitor") }
  end
end
