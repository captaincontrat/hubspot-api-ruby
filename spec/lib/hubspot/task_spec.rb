RSpec.describe Hubspot::Task do
  describe 'create!' do
    subject(:new_task) do
      params = {
        hs_task_body: 'i am a task',
        hs_task_subject: 'title of task',
        hs_timestamp: DateTime.now.strftime('%Q')
      }
      associations = [
        Hubspot::Association.build_association_param('Task', 'Ticket', 16_174_569_112),
        Hubspot::Association.build_association_param('Task', 'Contact', 75_761_595_194),
        Hubspot::Association.build_association_param('Task', 'Company', 25_571_271_600),
        Hubspot::Association.build_association_param('Task', 'Deal', 28_806_796_888)
      ]
      described_class.create!(params, associations:)
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

  describe 'search' do
    subject(:search) do
      body = { filterGroups: [
        { filters: [{ propertyName: 'associations.ticket', operator: 'EQ',
                      value: '16676542642' }] }
      ] }
      described_class.search(%w[hs_task_subject hs_task_status], body:)
    end

    it 'returns list of tasks matching search body' do
      VCR.use_cassette 'task_search' do
        expect(search['total']).to eq(2)
        expect(search['results'].map { |r| r['id'] }).to contain_exactly('65090432307', '65476695429')
      end
    end
  end

  describe 'update!' do
    let(:task_id) { 64_483_143_324 }
    let(:properties) do
      {
        hs_task_status: 'COMPLETED'
      }
    end

    subject(:update_task) { described_class.update!(task_id, properties) }

    it 'updates existing task, returns the updated entity' do
      VCR.use_cassette 'task_update' do
        task = update_task
        expect(task.properties[:hs_task_status]).to eq('COMPLETED')
      end
    end
  end
end
