describe Hubspot::TicketProperties do
  describe '.create' do
    context 'with no valid parameters' do
      it 'should return nil' do
        VCR.use_cassette 'ticket_fail_to_create_property' do
          expect(Hubspot::TicketProperties.create!({})).to be(nil)
        end
      end
    end

    context 'with all valid parameters' do
      let(:params) do
        {
          'name' => 'my_new_property',
          'label' => 'This is my new property',
          'description' => 'How much money do you have?',
          'groupName' => 'ticketinformation',
          'type' => 'string',
          'fieldType' => 'text',
          'hidden' => false,
          'deleted' => false,
          'displayOrder' => 0,
          'formField' => true,
          'readOnlyValue' => false,
          'readOnlyDefinition' => false,
          'mutableDefinitionNotDeletable' => false,
          'calculated' => false,
          'externalOptions' => false,
          'displayMode' => 'current_value'
        }
      end

      it 'should return the valid parameters' do
        VCR.use_cassette 'ticket_create_property' do
          response = Hubspot::TicketProperties.create!(params)
          expect(Hubspot::TicketProperties.same?(params, response.compact.except("options"))).to be true
        end
      end
    end
  end
end