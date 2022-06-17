describe Hubspot::Deal do
  let(:portal_id) { ENV.fetch("HUBSPOT_PORTAL_ID").to_i }
  let(:company) { Hubspot::Company.create(name: SecureRandom.hex) }
  let(:company_id) { company.id }
  let(:contact) { Hubspot::Contact.create("#{SecureRandom.hex}@hubspot.com") }
  let(:vid) { contact.id }
  let(:amount) { '30' }
  let(:deal) { Hubspot::Deal.create!(portal_id, [company_id], [vid], { amount: amount}) }

  describe ".create!" do
    cassette "deal_create"
    subject { Hubspot::Deal.create!(portal_id, [company_id], [vid], {}) }
    its(:deal_id)     { should_not be_nil }
    its(:portal_id)   { should eql portal_id }
    its(:company_ids) { should eql [company_id]}
    its(:vids)        { should eql [vid]}
  end

  describe '.update' do
    let(:changed_properties) { { dealname: 'super deal' } }

    context 'with an existing resource' do
      cassette
      subject { described_class.update(deal.deal_id, changed_properties) }

      it 'updates' do
        expect(subject).to be_truthy
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal['dealname']).to eq 'super deal'
      end
    end

    context 'with an invalid resource' do
      cassette
      subject { described_class.update(0, changed_properties) }

      it { is_expected.to be false }
    end
  end

  describe '.update!' do
    let(:changed_properties) { { dealname: 'super deal' } }

    context 'with an existing resource' do
      cassette
      subject { described_class.update!(deal.deal_id, changed_properties) }

      it 'updates' do
        expect(subject).to be_truthy
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal['dealname']).to eq 'super deal'
      end
    end

    context 'with an invalid resource' do
      cassette
      subject { described_class.update!(0, changed_properties) }

      it 'fails with an error' do
        expect { subject }.to raise_error Hubspot::RequestError
      end
    end
  end

  describe '#update' do
    let(:changed_properties) { { dealname: 'super deal' }.stringify_keys }

    context 'without overlapping changes' do
      cassette
      subject { deal.update(changed_properties) }

      it 'updates the properties' do
        expect(subject).to be_truthy
        changed_properties.each do |property, value|
          expect(deal[property]).to eq value
        end
      end
    end

    context 'with overlapping changes' do
      cassette
      subject { deal.update(changed_properties) }
      let(:overlapping_properties) { { dealname: 'old deal', amount: 6 }.stringify_keys }

      before(:each) do
        overlapping_properties.each { |property, value| deal.properties[property] = value }
      end

      it 'merges and updates the properties' do
        expect(subject).to be_truthy
        overlapping_properties.merge(changed_properties).each do |property, value|
          expect(deal[property]).to eq value
        end
      end
    end
  end

  describe '.associate' do
    cassette
    let(:deal) { Hubspot::Deal.create!(portal_id, [], [], {}) }
    let(:contact_id) { contact.id }

    subject { Hubspot::Deal.associate!(deal.deal_id, [company.id], [contact_id]) }

    it 'associates the deal to the contact and the company' do
      subject
      find_deal = Hubspot::Deal.find(deal.deal_id)
      find_deal.company_ids.should eql [company.id]
      find_deal.vids.should eql [contact.id]
    end

    context 'when an id is invalid' do
      let(:contact_id) { 1234 }

      it 'returns false and changes valid associations' do
        expect(subject).to eq(false)
        find_deal = Hubspot::Deal.find(deal.deal_id)
        find_deal.company_ids.should eql [company.id]
        find_deal.vids.should eql []
      end
    end
  end

  describe ".find" do
    cassette "deal_find"

    it 'must find by the deal id' do
      find_deal = Hubspot::Deal.find(deal.deal_id)
      find_deal.deal_id.should eql deal.deal_id
      find_deal.properties["amount"].should eql amount
    end
  end

  describe '.find_by_company' do
    cassette
    let!(:deal) { Hubspot::Deal.create!(portal_id, [company.id], [], { amount: amount }) }

    it 'returns company deals' do
      deals = Hubspot::Deal.find_by_company(company)
      deals.first.deal_id.should eql deal.deal_id
      deals.first.properties['amount'].should eql amount
    end
  end

  describe '.find_by_contact' do
    cassette
    let!(:deal) { Hubspot::Deal.create!(portal_id, [], [contact.id], { amount: amount }) }

    it 'returns contact deals' do
      deals = Hubspot::Deal.find_by_contact(contact)
      deals.first.deal_id.should eql deal.deal_id
      deals.first.properties['amount'].should eql amount
    end
  end

  describe '.recent' do
    cassette 'find_all_recent_updated_deals'

    it 'must get the recents updated deals' do
      deal
      deals = Hubspot::Deal.recent

      first = deals.first

      expect(first).to be_a Hubspot::Deal
    end

    it 'must filter only 2 deals' do
      3.times { Hubspot::Deal.create!(portal_id, [company_id], [vid], { amount: amount}) }
      deals = Hubspot::Deal.recent(count: 2)
      expect(deals.size).to eql 2
    end

  end

  describe "#destroy!" do
    it "should remove from hubspot" do
      VCR.use_cassette("destroy_deal") do
        result = deal.destroy!
        expect(result).to be true
      end
    end
  end
end
