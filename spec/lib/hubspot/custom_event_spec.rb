RSpec.describe Hubspot::CustomEvent do
  before do
    Hubspot.configure(access_token: ENV.fetch("HUBSPOT_ACCESS_TOKEN"), portal_id: ENV.fetch("HUBSPOT_PORTAL_ID"),
                      custom_event_prefix: 'foobar')
  end

  describe '.trigger' do
    let(:event_name) { 'my_awesome_event' }
    let(:email) { 'testingapis@hubspot.com' }
    let(:properties) { { prop_foo: 'bar' } }
    let(:options) { {} }
    let(:base_url) { 'https://api.hubapi.com' }
    let(:url) { "#{base_url}/events/v3/send" }

    subject { described_class.trigger(event_name, email, properties, options) }

    before { stub_request(:post, url).to_return(status: 204, body: JSON.generate({})) }

    it('sends a request to trigger the event') { is_expected.to be true }

    context 'with headers' do
      let(:headers) { { 'User-Agent' => 'something' } }
      let(:options) { { headers: headers } }

      it('sends headers') { is_expected.to be true }
    end
  end
end
