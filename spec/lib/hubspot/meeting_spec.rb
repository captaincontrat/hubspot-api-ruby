RSpec.describe Hubspot::Meeting do

  let(:hubspot_owner_id) do
    VCR.use_cassette('meeting_owner') do
      headers = { Authorization: "Bearer #{ENV.fetch('HUBSPOT_ACCESS_TOKEN')}" }
      owners = HTTParty.get('https://api.hubapi.com/owners/v2/owners', headers: headers).parsed_response
      owners.first['ownerId']
    end
  end
  let(:hs_meeting_title) { 'hs_meeting_title' }
  let(:hs_meeting_body) { 'hs_meeting_body' }
  let(:hs_meeting_start_time) { DateTime.strptime('2022-05-03T10:00:00+01:00', '%Y-%m-%dT%H:%M:%S%z') }
  let(:hs_meeting_end_time) { DateTime.strptime('2022-05-03T10:15:00+01:00', '%Y-%m-%dT%H:%M:%S%z') }

  describe '.create' do
    context 'with properties' do

      subject do
        described_class.create!(hubspot_owner_id,
                                hs_meeting_title,
                                hs_meeting_body,
                                hs_meeting_start_time,
                                hs_meeting_end_time)
      end

      it 'creates a new meeting with valid properties' do
        VCR.use_cassette 'meeting' do
          expect(subject[:id]).not_to be_nil
          expect(DateTime.parse(subject[:properties][:hs_meeting_start_time])).to eq(hs_meeting_start_time)
        end
      end
    end

    context 'with an invalid hs_meeting_start_time' do
      subject { described_class.create!(hubspot_owner_id,
                                        hs_meeting_title,
                                        hs_meeting_body,
                                        'invalid',
                                        hs_meeting_end_time) }

      it 'raises an error' do
        VCR.use_cassette 'meeting_error' do
          expect { subject }.to raise_error(Hubspot::RequestError)
        end
      end
    end
  end

  describe '#destroy!' do
    let(:meeting) do
      Hubspot::Meeting.create!(hubspot_owner_id,
                              hs_meeting_title,
                              hs_meeting_body,
                              hs_meeting_start_time,
                              hs_meeting_end_time)
    end

    it "should be destroyed" do
      VCR.use_cassette 'meeting_destroy' do
        expect(Hubspot::Meeting.destroy!(meeting[:id])).to be_truthy
      end
    end
  end

  describe '#associate!' do
    let(:contact) { create :contact }
    let(:meeting) do
      Hubspot::Meeting.create!(hubspot_owner_id,
                              hs_meeting_title,
                              hs_meeting_body,
                              hs_meeting_start_time,
                              hs_meeting_end_time)
    end

    it "should be success" do
      VCR.use_cassette 'meeting_associate' do
        expect(Hubspot::Meeting.associate!(meeting[:id], contact.id)).to be_truthy
      end
    end
  end
end
