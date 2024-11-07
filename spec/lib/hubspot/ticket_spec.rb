RSpec.describe Hubspot::Ticket do
  describe 'create!' do
    subject(:new_ticket) do
      params = {
        hs_pipeline: '0',
        hs_pipeline_stage: '1',
        hs_ticket_priority: "MEDIUM",
        subject: 'test ticket'
      }
      described_class.create!(params, contact_id: 75761595194, company_id: 25571271600, deal_id: 28806796888)
    end

    it 'creates a new ticket with valid properties' do
      VCR.use_cassette 'ticket' do
        expect(new_ticket.id).not_to be_nil
        expect(new_ticket.properties[:subject]).to eq('test ticket')
      end
    end
  end

  describe 'find' do
    let(:ticket_id) { 16174569112 }

    subject(:existing_ticket) { described_class.find(ticket_id) }

    it 'gets existing ticket' do
      VCR.use_cassette 'ticket_find' do
        expect(existing_ticket.id).not_to be_nil
        expect(existing_ticket.properties[:subject]).to eq('test ticket')
      end
    end

    context 'when ticket does not exist' do
      let(:ticket_id) { 996174569112 }

      it 'returns nil' do
        VCR.use_cassette 'ticket_find' do
          expect { existing_ticket }.to raise_error Hubspot::NotFoundError
        end
      end
    end
  end

  describe 'update!' do
    let(:ticket_id) { 16174569112 }
    let(:properties) do
      {
        hs_ticket_priority: "HIGH",
        subject: "New name"
      }
    end

    subject(:update_ticket) { described_class.update!(ticket_id, properties) }

    it 'updates existing ticket, returns the updated entity' do
      VCR.use_cassette 'ticket_update' do
        ticket = update_ticket
        ticket.properties[:subject] = "Updated name"
        ticket.properties[:subject] = "HIGH"
      end
    end
  end
end
