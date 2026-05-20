# frozen_string_literal: true
RSpec.describe Hubspot::ConversationThread do
  describe 'find' do
    let(:thread_id) { 3_176_297_853 }

    subject(:existing_thread) { described_class.find(thread_id, with_associations: true) }

    it 'gets existing conversation thread' do
      VCR.use_cassette 'conversation_thread_find' do
        expect(existing_thread.id).not_to be_nil
        expect(existing_thread.properties[:status]).to eq('OPEN')
        expect(existing_thread.properties[:threadAssociations]).to eq(associatedTicketId: '21514722825')
      end
    end

    context 'when task does not exist' do
      let(:thread_id) { 996_174_569_112 }

      it 'raises an error' do
        VCR.use_cassette 'conversation_thread_find' do
          expect { existing_thread }.to raise_error Hubspot::NotFoundError
        end
      end
    end
  end
end
