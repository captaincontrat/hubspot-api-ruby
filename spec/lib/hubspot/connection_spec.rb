describe Hubspot::Connection do
  describe ".get_json" do
    it "returns the parsed response from the GET request" do
      path = "/some/path"
      body = { key: "value" }

      stub_request(:get, "https://api.hubapi.com/some/path").to_return(status: 200, body: JSON.generate(body))

      result = Hubspot::Connection.get_json(path, {})
      expect(result).to eq({ "key" => "value" })
    end
  end

  describe ".post_json" do
    it "returns the parsed response from the POST request" do
      path = "/some/path"
      body = { id: 1, name: "ABC" }

      stub_request(:post, "https://api.hubapi.com/some/path?name=ABC").to_return(status: 200, body: JSON.generate(body))

      result = Hubspot::Connection.post_json(path, params: { name: "ABC" })
      expect(result).to eq({ "id" => 1, "name" => "ABC" })
    end
  end

  describe ".delete_json" do
    it "returns the response from the DELETE request" do
      path = "/some/path"

      stub_request(:delete, "https://api.hubapi.com/some/path").to_return(status: 204, body: JSON.generate({}))

      result = Hubspot::Connection.delete_json(path, {})
      expect(result.code).to eq(204)
    end
  end

  describe ".put_json" do
    it "issues a PUT request and returns the parsed body" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      stub_request(:put, "https://api.hubapi.com/some/path").to_return(status: 200, body: JSON.generate(vid: 123))

      response = Hubspot::Connection.put_json(path, update_options)

      assert_requested(
        :put,
        "https://api.hubapi.com/some/path",
         {
           body: "{}",
           headers: { "Content-Type" => "application/json" },
         }
      )
      expect(response).to eq({ "vid" => 123 })
    end

    it "logs information about the request and response" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      logger = stub_logger

      stub_request(:put, "https://api.hubapi.com/some/path").to_return(status: 200,
                                                                       body: JSON.generate("response body"))

      Hubspot::Connection.put_json(path, update_options)

      expect(logger).to have_received(:info).with(<<~MSG)
        Hubspot: https://api.hubapi.com/some/path.
        Body: {}.
        Response: 200 "response body"
      MSG
    end

    it "raises when the request fails" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      stub_request(:put, "https://api.hubapi.com/some/path").to_return(status: 401)

      expect {
        Hubspot::Connection.put_json(path, update_options)
      }.to raise_error(Hubspot::RequestError)
    end
  end

  describe ".patch_json" do
    it "issues a PATCH request and returns the parsed body" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      stub_request(:patch, "https://api.hubapi.com/some/path").to_return(status: 200, body: JSON.generate(vid: 123))

      response = Hubspot::Connection.patch_json(path, update_options)

      assert_requested(
        :patch,
        "https://api.hubapi.com/some/path",
        {
          body: "{}",
          headers: { "Content-Type" => "application/json" },
        }
      )
      expect(response).to eq({ "vid" => 123 })
    end

    it "logs information about the request and response" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      logger = stub_logger

      stub_request(:patch, "https://api.hubapi.com/some/path").to_return(status: 200,
                                                                       body: JSON.generate("response body"))

      Hubspot::Connection.patch_json(path, update_options)

      expect(logger).to have_received(:info).with(<<~MSG)
        Hubspot: https://api.hubapi.com/some/path.
        Body: {}.
        Response: 200 "response body"
      MSG
    end

    it "raises when the request fails" do
      path = "/some/path"
      update_options = { params: {}, body: {} }

      stub_request(:patch, "https://api.hubapi.com/some/path").to_return(status: 401)

      expect {
        Hubspot::Connection.patch_json(path, update_options)
      }.to raise_error(Hubspot::RequestError)
    end
  end

  context 'private methods' do
    describe ".generate_url" do
      let(:path) { "/test/:email/profile" }
      let(:params) { { email: "test" } }
      let(:options) { {} }
      subject { Hubspot::Connection.send(:generate_url, path, params, options) }

      it "doesn't modify params" do
        expect { subject }.to_not change{params}
      end

      context "with a portal_id param" do
        let(:path) { "/test/:portal_id/profile" }
        let(:params) { {} }

        before do
          Hubspot.configure(access_token: ENV.fetch("HUBSPOT_ACCESS_TOKEN"), portal_id: ENV.fetch("HUBSPOT_PORTAL_ID"))
        end

        it { should == "https://api.hubapi.com/test/#{ENV.fetch('HUBSPOT_PORTAL_ID')}/profile" }
      end

      context "when configure hasn't been called" do
        before { Hubspot::Config.reset! }
        it "raises a config exception" do
          expect { subject }.to raise_error Hubspot::ConfigurationError
        end
      end

      context "with interpolations but no params" do
        let(:params) { {} }

        it "raises an interpolation exception" do
          expect{ subject }.to raise_error Hubspot::MissingInterpolation
        end
      end

      context "with an interpolated param" do
        let(:params) { { email: "email@address.com" } }
        it { should == "https://api.hubapi.com/test/email%40address.com/profile" }
      end

      context "with multiple interpolated params" do
        let(:path) { "/test/:email/:id/profile" }
        let(:params) { { email: "email@address.com", id: 1234 } }
        it { should == "https://api.hubapi.com/test/email%40address.com/1234/profile" }
      end

      context "with query params" do
        let(:params) { { email: "email@address.com", id: 1234 } }
        it { should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234" }

        context "containing a time" do
          let(:start_time) { Time.now }
          let(:params) { { email: "email@address.com", id: 1234, start: start_time } }
          it { should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&start=#{start_time.to_i * 1000}" }
        end

        context "containing a range" do
          let(:start_time) { Time.now }
          let(:end_time) { Time.now + 1.year }
          let(:params) { { email: "email@address.com", id: 1234, created__range: start_time..end_time  } }
          it { should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&created__range=#{start_time.to_i * 1000}&created__range=#{end_time.to_i * 1000}" }
        end

        context "containing an array of strings" do
          let(:path) { "/test/emails" }
          let(:params) { { batch_email: %w(email1@example.com email2@example.com) } }
          it { should == "https://api.hubapi.com/test/emails?email=email1%40example.com&email=email2%40example.com" }
        end
      end

      context "with options" do
        let(:options) { { base_url: "https://cool.com", access_token: false } }
        it { should == "https://cool.com/test/test/profile" }
      end

      context "passing Array as parameters for batch mode, key is prefixed with batch_" do
        let(:path) { Hubspot::ContactList::LIST_BATCH_PATH }
        let(:params) { { batch_list_id: [1,2,3] } }
        it { should == "https://api.hubapi.com/contacts/v1/lists/batch?listId=1&listId=2&listId=3" }
      end
    end
  end

  def stub_logger
    instance_double(Logger, info: true).tap do |logger|
      allow(Hubspot::Config).to receive(:logger).and_return(logger)
    end
  end
end

describe Hubspot::EventConnection do
  describe '.trigger' do
    let(:path) { '/path' }
    let(:options) { { params: {} } }
    let(:headers) { nil }

    subject { described_class.trigger(path, options) }
    before { allow(described_class).to receive(:get).and_return(true) }

    it 'calls get with a custom url' do
      subject
      expect(described_class).to have_received(:get).with('https://track.hubspot.com/path', body: nil, headers: nil)
    end

    context 'with more options' do
      let(:headers) { { 'User-Agent' => 'something' } }
      let(:options) { { params: {}, headers: headers } }

      it 'supports headers' do
        subject
        expect(described_class).to have_received(:get).with('https://track.hubspot.com/path', body: nil, headers: headers)
      end
    end
  end
end
