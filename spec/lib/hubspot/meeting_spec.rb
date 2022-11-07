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

  describe '.all' do
    let(:options) { {} }
    subject(:all) do
      described_class.all(options)
    end

    it 'retrieves all the meetings with default limit' do
      VCR.use_cassette 'meeting_all' do
        meetings = all
        expect(meetings).not_to be_nil
        expect(meetings[:meetings].many?).to be true
        expect(meetings[:meetings].first).to be_a(Hubspot::Meeting)
      end
    end

    context 'with a limit' do
      let(:options) { { limit: 2 } }
      it 'retrieves all the meetings within limit' do
        VCR.use_cassette 'meeting_all_limit' do
          meetings = all
          expect(meetings).not_to be_nil
          expect(meetings[:meetings].count).to eq 2
          expect(meetings[:meetings].first).to be_a(Hubspot::Meeting)
          expect(meetings[:after]).not_to be nil
        end
      end
    end

    context 'with a limit and an after param' do
      let(:options) { { limit: 3, after: '12642400565' } }

      it 'retrives the next meetings within limit after a given id' do
        VCR.use_cassette 'meeting_all_limit_after' do
          meetings = all
          expect(meetings).not_to be_nil
          expect(meetings[:meetings].count).to eq 3
          expect(meetings[:meetings].first).to be_a(Hubspot::Meeting)
          expect(meetings[:after]).not_to be nil
        end
      end
    end
  end

  describe '.find' do
    subject(:find) do
      described_class.find(27195487241)
    end

    it 'retrieves the meeting' do
      VCR.use_cassette 'meeting_find' do
        meeting = find
        expect(meeting).not_to be_nil
        expect(meeting.properties[:hubspot_owner_id]).not_to be nil
        expect(meeting.properties[:hs_meeting_title]).not_to be nil
        expect(meeting.properties[:hs_meeting_body]).not_to be nil
        expect(meeting.properties[:hs_meeting_start_time]).not_to be nil
        expect(meeting.properties[:hs_meeting_end_time]).not_to be nil
      end
    end
  end

  describe ".find_by_contact" do
    subject(:find_by_contact) do
      described_class.find_by_contact(1451)
    end

    it 'retrieves meetings' do
      VCR.use_cassette 'meeting_find_by_contact' do
        meetings = find_by_contact
        first_meeting = meetings.first
        expect(meetings).not_to be_nil
        expect(first_meeting).not_to be_nil
        expect(first_meeting.properties[:hubspot_owner_id]).not_to be nil
        expect(first_meeting.properties[:hs_meeting_title]).not_to be nil
        expect(first_meeting.properties[:hs_meeting_body]).not_to be nil
        expect(first_meeting.properties[:hs_meeting_start_time]).not_to be nil
        expect(first_meeting.properties[:hs_meeting_end_time]).not_to be nil
      end
    end
  end

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
