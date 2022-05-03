RSpec.describe Hubspot::CustomEvent do
  let(:portal_id) { '62515' }
  let(:sent_portal_id) { portal_id }
  before { Hubspot.configure(hapikey: 'demo', custom_event_prefix: 'foobar') }

  describe '.trigger' do
    let(:event_name) { 'my_awesome_event' }
    let(:email) { 'testingapis@hubspot.com' }
    let(:properties) { { prop_foo: 'bar' } }
    let(:options) { {} }
    let(:base_url) { 'https://api.hubapi.com' }
    let(:url) { "#{base_url}/events/v3/send?hapikey=demo" }

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
