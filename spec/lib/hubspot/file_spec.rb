describe Hubspot do
  describe Hubspot::File do
    before { Hubspot.configure(hapikey: "demo") }
    describe ".find_by_id" do
      it "should fetch specific file" do
        VCR.use_cassette("file_find") do
          file = Hubspot::File.find_by_id(5323360053)
          file.id.should eq(5323360053)
        end
      end
    end
  end
end
