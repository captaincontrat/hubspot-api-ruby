describe Hubspot::File do
  let(:example_file_hash) do
    VCR.use_cassette('file_example') do
      headers = { Authorization: "Bearer #{ENV.fetch('HUBSPOT_ACCESS_TOKEN')}" }
      body = {
        file: File.open(File::NULL, 'r'),
        options: { access: 'PRIVATE', ttl: 'P1M', overwrite: false }.to_json,
        folderPath: '/'
      }
      url = 'https://api.hubapi.com/filemanager/api/v3/files/upload'
      HTTParty.post(url, body: body, headers: headers).parsed_response
    end
  end

  describe ".find_by_id" do
    it "should fetch specific file" do
      VCR.use_cassette("file_find") do
        id = example_file_hash['objects'].first['id']
        file = Hubspot::File.find_by_id(id)
        file.id.should eq(id)
      end
    end
  end
end
