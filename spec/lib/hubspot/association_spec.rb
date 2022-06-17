RSpec.describe Hubspot::Association do
  let(:portal_id) { 62515 }
  let(:company) { create :company }
  let(:contact) { create :contact }

  describe '.create' do
    context 'with a valid ID' do
      cassette
      subject { described_class.create("Company", company.id, "Contact", contact.id) }

      it 'associates the resources' do
        expect(subject).to be true
        expect(company.contact_ids.resources).to eq [contact.id]
      end
    end

    context 'with an invalid ID' do
      cassette
      subject { described_class.create("Company", 1234, "Contact", 1234) }

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  describe '.batch_create' do
    let(:deal) { Hubspot::Deal.create!(portal_id, [], [], {}) }
    let(:contact2) { create :contact }

    subject { described_class.batch_create(*associations) }

    context 'with a valid request' do
      cassette
      let(:associations) do
        [
          "Deal",
          "Contact",
          [
            { from_id: deal.deal_id, to_id: contact.id},
            { from_id: deal.deal_id, to_id: contact2.id}
          ]
        ]
      end

      it 'associates the resources' do
        expect(subject).to be true
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.vids).to eq [contact.id, contact2.id]
      end
    end

    context 'with an invalid ID' do
      cassette
      let(:associations) do
        [
          "Deal",
          "Contact",
          [
            { from_id: deal.deal_id, to_id: 1234 }
          ]
        ]
      end

      it 'returns false' do
        expect(subject).to eq(false)
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.vids).to eq []
      end
    end
  end

  describe '.delete' do
    subject { described_class.delete("Company", company.id, "Contact", contact_id_to_dissociate) }
    before { described_class.create("Company", company.id, "Contact", contact.id) }

    context 'with a valid ID' do
      cassette
      let(:contact_id_to_dissociate) { contact.id }

      it 'dissociates the resources' do
        expect(subject).to be true
        expect(company.contact_ids.resources).to eq []
      end
    end

    context 'with an invalid ID' do
      cassette
      let(:contact_id_to_dissociate) { 1234 }

      it 'does not raise an error' do
        expect(subject).to be true
        expect(company.contact_ids.resources).to eq [contact.id]
      end
    end
  end

  describe '.batch_delete' do
    let(:company2) { create(:company) }
    let(:deal) { Hubspot::Deal.create!(portal_id, [company.id, company2.id], [], {}) }

    subject { described_class.batch_delete("Deal", "Company", associations) }

    context 'with a valid request' do
      cassette
      let(:associations) do
        [
          { from_id: deal.deal_id, to_id: company.id },
          { from_id: deal.deal_id, to_id: company2.id }
        ]
      end

      it 'dissociates the resources' do
        expect(subject).to be true
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.company_ids).to eq []
      end
    end

    context 'with an invalid ID' do
      cassette
      let(:associations) do
        [
          { from_id: deal.deal_id, to_id: 1234 },
          { from_id: deal.deal_id, to_id: company.id }
        ]
      end

      it 'does not raise an error, removes the valid associations' do
        expect(subject).to be true
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.company_ids).to eq [company2.id]
      end
    end
  end

  describe '.all' do
    subject { described_class.all(resource_type, resource_id, to_object_type) }

    context 'with valid params' do
      cassette

      let(:resource_type) { "Deal" }
      let(:resource_id) { deal.deal_id }
      let(:to_object_type) { "Contact" }
      let(:deal) { Hubspot::Deal.create!(portal_id, [], contact_ids, {}) }
      let(:contact_ids) { [contact.id, second_contact.id] }
      let(:second_contact) { create :contact }

      it 'finds the resources' do
        expect(subject.map(&:id)).to contain_exactly(*contact_ids)
      end
    end

    context 'with unsupported object_type' do
      let(:resource_type) { "Contact" }
      let(:resource_id) { 1234 }
      let(:to_object_type) { "Foo" }

      it 'raises an error' do
        expect { subject }.to raise_error(Hubspot::InvalidParams, 'Object type not supported')
      end
    end
  end
end
