require "rails_helper"

RSpec.describe DurationParser do
  describe ".parse" do
    it "parses bare seconds" do
      expect(described_class.parse("30")).to eq(30)
      expect(described_class.parse("0")).to eq(0)
      expect(described_class.parse("3600")).to eq(3600)
    end

    it "parses seconds with s suffix" do
      expect(described_class.parse("30s")).to eq(30)
      expect(described_class.parse("10sec")).to eq(10)
      expect(described_class.parse("45secs")).to eq(45)
      expect(described_class.parse("5seconds")).to eq(5)
    end

    it "parses minutes with m suffix" do
      expect(described_class.parse("5m")).to eq(300)
      expect(described_class.parse("10min")).to eq(600)
      expect(described_class.parse("2mins")).to eq(120)
      expect(described_class.parse("1minute")).to eq(60)
      expect(described_class.parse("3minutes")).to eq(180)
    end

    it "parses hours with h suffix" do
      expect(described_class.parse("6h")).to eq(21_600)
      expect(described_class.parse("1hr")).to eq(3600)
      expect(described_class.parse("2hrs")).to eq(7200)
      expect(described_class.parse("4hour")).to eq(14_400)
      expect(described_class.parse("3hours")).to eq(10_800)
    end

    it "handles spaces between number and unit" do
      expect(described_class.parse("30 s")).to eq(30)
      expect(described_class.parse("5 m")).to eq(300)
      expect(described_class.parse("2 h")).to eq(7200)
    end

    it "returns nil for invalid formats" do
      expect(described_class.parse("abc")).to be_nil
      expect(described_class.parse("1.5m")).to be_nil
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end
  end

  describe ".format" do
    it "formats seconds only" do
      expect(described_class.format(30)).to eq("30 seconds")
      expect(described_class.format(1)).to eq("1 second")
    end

    it "formats minutes" do
      expect(described_class.format(60)).to eq("1 minute")
      expect(described_class.format(300)).to eq("5 minutes")
    end

    it "formats hours" do
      expect(described_class.format(3600)).to eq("1 hour")
      expect(described_class.format(7200)).to eq("2 hours")
    end

    it "formats hours and minutes" do
      expect(described_class.format(3660)).to eq("1 hour 1 minute")
      expect(described_class.format(7260)).to eq("2 hours 1 minute")
    end

    it "returns nil for nil" do
      expect(described_class.format(nil)).to be_nil
    end

    it "handles zero" do
      expect(described_class.format(0)).to eq("0 seconds")
    end

    it "handles negative values" do
      expect(described_class.format(-30)).to eq("0 seconds")
    end
  end
end
