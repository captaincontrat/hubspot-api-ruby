RSpec.describe Hubspot::DealPipeline do

  describe ".find" do
    it "retrieves a record by id" do
      VCR.use_cassette("find_deal_pipeline") do
        deal_pipeline = Hubspot::DealPipeline.create!(label: "New Pipeline #{SecureRandom.hex}")
        id = deal_pipeline.pipeline_id

        result = Hubspot::DealPipeline.find(deal_pipeline.pipeline_id)

        expect(result).to be_a(Hubspot::DealPipeline)

        deal_pipeline.destroy!
      end
    end
  end

  describe ".all" do
    it "returns a list" do
      VCR.use_cassette("all_deal_pipelines") do
        deal_pipeline = Hubspot::DealPipeline.create!(label: "New Pipeline #{SecureRandom.hex}")

        results = Hubspot::DealPipeline.all

        expect(results).to be_kind_of(Array)
        expect(results.first).to be_a(Hubspot::DealPipeline)

        deal_pipeline.destroy!
      end
    end
  end

  describe ".create!" do
    it "creates a new record" do
      VCR.use_cassette("create_deal_pipeline") do
        result = Hubspot::DealPipeline.create!(label: "New Pipeline #{SecureRandom.hex}")

        expect(result).to be_a(Hubspot::DealPipeline)

        result.destroy!
      end
    end
  end

  describe "#destroy!" do
    it "deletes the record" do
      VCR.use_cassette("delete_deal_pipeline") do
        deal_pipeline = Hubspot::DealPipeline.create!(label: "New Pipeline #{SecureRandom.hex}")
        id = deal_pipeline.pipeline_id

        result = deal_pipeline.destroy!

        expect(result).to be_a(HTTParty::Response)
      end
    end
  end

  describe "#[]" do
    it "returns the stage at the specified index" do
      data = {
        "stages" => [
          {"active": true, "label": "New Lead"},
          {"active": true, "label": "Proposal"},
        ],
      }

      deal_pipeline = Hubspot::DealPipeline.new(data)

      result = deal_pipeline[0]

      expect(result).to eq(data["stages"][0])
    end
  end
end
