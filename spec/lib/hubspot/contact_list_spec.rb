describe Hubspot::ContactList do
  # uncomment if you need to create test data in your panel.
  # note that sandboxes have a limit of 10 dynamic lists
  # before(:all) do
  #   VCR.use_cassette("create_all_lists") do
  #     25.times { Hubspot::ContactList.create!(name: SecureRandom.hex) }
  #     3.times { Hubspot::ContactList.create!(name: SecureRandom.hex, processing_type: 'DYNAMIC', "filterBranch": { "filterBranches": [{ "filterBranches": [], "filterBranchType": "AND", "filters": [{ "filterType": "PROPERTY", property: "twitterhandle", operation: { operationType: 'STRING', operator: 'IS_EQUAL_TO', value: '@hubspot'}}]}], "filterBranchType": "OR", "filters": [] } ) }
  #   end
  # end

  let(:static_list) do
    Hubspot::ContactList.create!(name: "static list #{SecureRandom.hex}")
  end

  describe '#initialize' do
    subject { Hubspot::ContactList.new(example_contact_list_hash) }

    let(:example_contact_list_hash) do
      VCR.use_cassette("contact_list_example") do
        headers = { Authorization: "Bearer #{ENV.fetch('HUBSPOT_ACCESS_TOKEN')}" }
        response = HTTParty.get("https://api.hubapi.com/contacts/v1/lists?count=2", headers: headers).parsed_response
        response['lists'].last
      end
    end

    it { should be_an_instance_of Hubspot::ContactList }
    its(:name) { should_not be_empty }
    its(:processing_type) { should be_nil }
    its(:properties) { should be_a(Hash) }
  end

  describe '#contact_ids' do
    cassette 'contacts_among_list'

    let(:list) { @list }

    before(:all) do
      VCR.use_cassette 'create_and_add_all_contacts' do
        @list = Hubspot::ContactList.create!(name: "contacts list #{SecureRandom.hex}")
        contacts = (1..30).map { Hubspot::Contact.create("#{SecureRandom.hex}@hubspot.com") }
        @list.add(contacts.map(&:id))
      end
    end

    it 'returns by default 25 contact lists with paging data' do
      results = list.contact_ids
      expect(results).to be_a(Hubspot::PagedCollection)
      expect(results.first).to be_a(String)
      expect(results.more?).to be true
      expect(results.count).to eql 25
    end
  end

  describe '.create' do
    subject { Hubspot::ContactList.create!(name:) }

    context 'with all required parameters' do
      cassette 'create_list'

      let(:name) { "testing list #{SecureRandom.hex}" }
      it { should be_an_instance_of Hubspot::ContactList }
      its(:processing_type) { should eq described_class::MANUAL_PROCESSING_TYPE }

      context 'adding filters parameters' do
        cassette 'create_list_with_filters'

        it 'returns a ContactList object with filters set' do
          name = "list with filters #{SecureRandom.hex}"
          filter_branch = { filterBranches: [
            { filterBranches: [], filterBranchType: "AND", filters: [
              { filterType: "PROPERTY", property: "twitterhandle",
                operation: { operationType: 'STRING', operator: 'IS_EQUAL_TO', value: '@hubspot'} }
            ]}
          ], filterBranchType: "OR", filters: [] }

          list_with_filters = Hubspot::ContactList.create!(processing_type: 'DYNAMIC', name: name,
                                                           filterBranch: filter_branch)
          expect(list_with_filters).to be_a(Hubspot::ContactList)
          expect(list_with_filters.properties['filterBranch']).to_not be_empty
          expect(list_with_filters.processing_type).to eq 'DYNAMIC'
        end
      end
    end

    context 'without all required parameters' do
      cassette 'fail_to_create_list'

      it 'raises an error' do
        expect { Hubspot::ContactList.create!(name: nil) }.to raise_error(Hubspot::RequestError)
      end
    end
  end

  describe '.all' do
    cassette 'find_all_lists'

    it 'returns by default 20 contact lists' do
      lists = Hubspot::ContactList.all
      expect(lists).to be_a(Hubspot::PagedCollection)
      expect(lists.count).to eql 20

      list = lists.first
      expect(list).to be_a(Hubspot::ContactList)
      expect(list.id).to be_present
    end
  end

  describe '.find' do
    context 'given an id' do
      cassette "contact_list_find"
      subject { Hubspot::ContactList.find(id) }

      let(:list) { Hubspot::ContactList.create!(name: SecureRandom.hex) }

      context 'when the contact list is found' do
        let(:id) { list.id.to_i }
        it { should be_an_instance_of Hubspot::ContactList }
        its(:name) { should == list.name }

        context "string id" do
          let(:id) { list.id.to_s }
          it { should be_an_instance_of Hubspot::ContactList }
          its(:name) { should == list.name }
        end
      end

      context 'Wrong parameter type given' do
        it 'raises an error' do
          expect { Hubspot::ContactList.find(foo: :bar) }.to raise_error(Hubspot::InvalidParams)
        end
      end

      context 'when the contact list is not found' do
        it 'raises an error' do
          expect { Hubspot::ContactList.find(-1) }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end

    context 'given a list of ids' do
      cassette "contact_list_batch_find"

      let(:list1) { Hubspot::ContactList.create!(name: SecureRandom.hex) }
      let(:list2) { Hubspot::ContactList.create!(name: SecureRandom.hex) }
      let(:list3) { Hubspot::ContactList.create!(name: SecureRandom.hex) }

      it 'find lists of contacts' do
        lists = Hubspot::ContactList.find([list1.id,list2.id,list3.id])
        list = lists.first
        expect(list).to be_a(Hubspot::ContactList)
        expect(lists.map(&:id)).to contain_exactly(list1.id, list2.id, list3.id)
      end
    end
  end

  describe "#add" do
    context "for a static list" do
      it "adds the contact to the contact list" do
        VCR.use_cassette("contact_lists/add_contact") do
          contact = Hubspot::Contact.create("#{SecureRandom.hex}@example.com")
          contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
          contact_list = Hubspot::ContactList.create!(contact_list_params)

          result = contact_list.add([contact.id])

          expect(result).to be true

          contact.delete
          contact_list.destroy!
        end
      end

      context "when the contact already exists in the contact list" do
        it "returns false" do
          VCR.use_cassette("contact_lists/add_existing_contact") do
            contact = Hubspot::Contact.create("#{SecureRandom.hex}@example.com")

            contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
            contact_list = Hubspot::ContactList.create!(contact_list_params)
            contact_list.add([contact.id])

            result = contact_list.add([contact.id])

            expect(result).to be false

            contact.delete
            contact_list.destroy!
          end
        end
      end
    end

    context "for a dynamic list" do
      it "raises an error as dynamic lists add contacts via on filters" do
        VCR.use_cassette("contact_list/add_contact_to_dynamic_list") do
          contact = Hubspot::Contact.create("#{SecureRandom.hex}@example.com")
          filter_branch = {
            filterBranches: [{ filterBranches: [], filterBranchType: "AND", filters: [
              { filterType: "PROPERTY", property: "twitterhandle",
                operation: { operationType: 'STRING', operator: 'IS_EQUAL_TO', value: '@hubspot'}}
              ]}], filterBranchType: "OR", filters: []
          }
          contact_list_params = {
            name: "my-contacts-list-#{SecureRandom.hex}",
            processing_type: 'DYNAMIC',
            filterBranch: filter_branch
          }
          contact_list = Hubspot::ContactList.create!(contact_list_params)

          expect {
            contact_list.add(contact)
          }.to raise_error(Hubspot::RequestError)
        end
      end
    end
  end

  describe '#remove' do
    it 'returns true if removes all contacts' do
      VCR.use_cassette("contact_lists/remove_contact") do
        contact_ids = (1..2).map { Hubspot::Contact.create("#{SecureRandom.hex}@example.com").id }
        contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
        contact_list = Hubspot::ContactList.create!(contact_list_params)

        contact_list.add(contact_ids)
        result = contact_list.remove(contact_ids)

        expect(result).to be true

        contact_list.destroy!
      end
    end

    it 'returns false if the contact cannot be removed' do
      VCR.use_cassette("contact_lists/remove_unknown_contact") do
        contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
        contact_list = Hubspot::ContactList.create!(contact_list_params)
        result = contact_list.remove([42])
        expect(result).to be false

        contact_list.destroy!
      end
    end
  end

  describe '#update_name!' do
    cassette "contact_list_update"

    subject { static_list.update_name!("updated list name") }

    it { should be_an_instance_of Hubspot::ContactList }
    its(:name){ should == "updated list name" }

    after { static_list.destroy! }
  end

  describe '#destroy!' do
    cassette "contact_list_destroy"

    subject{ static_list.destroy! }
    it { should be true }

    it "should be destroyed" do
      subject
      expect(static_list).to be_destroyed
    end
  end
end
