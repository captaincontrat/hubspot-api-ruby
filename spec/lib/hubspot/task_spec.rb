RSpec.describe Hubspot::Task do
  describe 'create!' do
    subject(:new_task) do
      params = {
        hs_task_body: 'i am a task',
        hs_task_subject: 'title of task',
        hs_timestamp: DateTime.now.strftime('%Q')
      }
      described_class.create!(params, ticket_id: 16_174_569_112)
    end

    it 'creates a new task with valid properties' do
      VCR.use_cassette 'task' do
        expect(new_task.id).not_to be_nil
        expect(new_task.properties[:hs_task_status]).to eq('NOT_STARTED')
        expect(new_task.properties[:hs_task_subject]).to eq('title of task')
        expect(new_task.properties[:hs_body_preview]).to eq('i am a task')
      end
    end
  end

  describe 'find' do
    let(:task_id) { 64_075_014_222 }

    subject(:existing_task) { described_class.find(task_id, 'hs_task_subject,hs_task_status') }

    it 'gets existing task' do
      VCR.use_cassette 'task_find' do
        expect(existing_task.id).not_to be_nil
        expect(existing_task.properties[:hs_task_subject]).to eq('title of task')
      end
    end

    context 'when task does not exist' do
      let(:task_id) { 996_174_569_112 }

      it 'returns nil' do
        VCR.use_cassette 'task_find' do
          expect { existing_task }.to raise_error Hubspot::NotFoundError
        end
      end
    end
  end
end
