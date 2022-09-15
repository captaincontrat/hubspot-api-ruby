describe Hubspot::DealProperties do
  describe '.add_default_parameters' do
    let(:opts) { {} }
    subject { Hubspot::DealProperties.add_default_parameters(opts) }
    context 'default parameters' do
      context 'without property parameter' do
        its([:property]) { should == 'email' }
      end

      context 'with property parameter' do
        let(:opts) { {property: 'dealname' } }
        its([:property]) { should == 'dealname'}
      end
    end
  end


  describe 'Properties' do
    describe '.all' do
      let(:groups) { %w(calltrackinginfo emailinformation) }

      context 'with included groups' do
        cassette 'deal_properties_in_groups'

        it 'should return properties for the specified group[s]' do
          response = Hubspot::DealProperties.all({}, { include: groups })
          response.each { |p| expect(groups.include?(p['groupName'])).to be true }
        end
      end

      context 'with excluded groups' do
        cassette 'deal_properties_not_in_groups'

        it 'should return properties for the non-specified group[s]' do
          response = Hubspot::DealProperties.all({}, { exclude: groups })
          response.each { |p| expect(groups.include?(p['groupName'])).to be false }
        end
      end
    end
    
    describe '.find' do
      context 'existing property' do
        cassette 'deal_properties/existing_property'

        it 'should return a deal property by name if it exists' do
          response = Hubspot::DealProperties.find('hs_acv')
          expect(response['name']).to eq 'hs_acv'
          expect(response['label']).to eq 'Annual contract value'
        end
      end

      context 'non-existent property' do
        cassette 'deal_properties/non_existent_property'

        it 'should return an error for a missing property' do
          expect{ Hubspot::DealProperties.find('this_does_not_exist') }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end

    let(:params) { {
      'name'                          => "my_new_property_#{SecureRandom.hex}",
      'label'                         => 'This is my new property',
      'description'                   => 'How much money do you have?',
      'groupName'                     => 'dealinformation',
      'type'                          => 'string',
      'fieldType'                     => 'text',
      'hidden'                        => false,
      'deleted'                       => false,
      'displayOrder'                  => 0,
      'formField'                     => true,
      'readOnlyValue'                 => false,
      'readOnlyDefinition'            => false,
      'mutableDefinitionNotDeletable' => false,
      'calculated'                    => false,
      'externalOptions'               => false,
      'displayMode'                   => 'current_value'
    } }

    describe '.create!' do
      context 'with no valid parameters' do
        cassette 'deal_fail_to_create_property'

        it 'should return nil' do
          expect(Hubspot::DealProperties.create!({})).to be(nil)
        end
      end

      context 'with all valid parameters' do
        cassette 'deal_create_property'

        it 'should return the valid parameters' do
          response = Hubspot::DealProperties.create!(params)
          expect(Hubspot::DealProperties.same?(params.except("name"), response.compact.except("name", "options"))).to be true
        end
      end
    end

    describe '.update!' do
      context 'with no valid parameters' do

        it 'should return nil ' do
          expect(Hubspot::DealProperties.update!(params['name'], {})).to be(nil)
        end
      end

      context 'with mixed parameters' do
        cassette 'deal_update_property'

        it 'should return the valid parameters' do
          properties = Hubspot::DealProperties.create!(params)
          params['description'] = 'What is their favorite flavor?'

          response = Hubspot::DealProperties.update!(properties['name'], params)
          expect(Hubspot::DealProperties.same?(response.compact.except("name"), params.except("name"))).to be true
        end
      end
    end

    describe '.delete!' do
      context 'with existing property' do
        cassette 'deal_delete_property'

        it 'should return nil' do
          properties = Hubspot::DealProperties.create!(params)
          expect(Hubspot::DealProperties.delete!(properties["name"])).to eq(nil)
        end
      end

      context 'with non-existent property' do
        cassette 'deal_delete_non_property'

        it 'should raise an error' do
          expect { Hubspot::DealProperties.delete!("i_do_not_exist") }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end
  end

  describe 'Groups' do
    describe '.groups' do
      let(:groups) { %w(calltrackinginfo emailinformation) }

      context 'with included groups' do
        cassette 'deal_groups_included'

        it 'should return the specified groups' do
          response = Hubspot::DealProperties.groups({}, { include: groups })
          response.each { |p| expect(groups.include?(p['name'])).to be true }
        end
      end

      context 'with excluded groups' do
        cassette 'deal_groups_not_excluded'

        it 'should return groups that were not excluded' do
          response = Hubspot::DealProperties.groups({}, { exclude: groups })
          response.each { |p| expect(groups.include?(p['name'])).to be false }
        end
      end
    end

    describe '.find_group' do
      context 'existing group' do
        cassette 'deal_properties/existing_group'

        it 'should return a deal property by name if it exists' do
          response = Hubspot::DealProperties.find_group('deal_revenue')
          expect(response['name']).to eq 'deal_revenue'
          expect(response['displayName']).to eq 'Deal revenue'
        end
      end

      context 'non-existent group' do
        cassette 'deal_properties/non_existent_group'

        it 'should return an error for a missing group' do
          expect{ Hubspot::DealProperties.find_group('this_does_not_exist') }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end

    let(:params) { { 'name' => 'ff_group1', 'displayName' => 'Test Group One', 'displayOrder' => 100, 'badParam' => 99 } }

    describe '.create_group!' do
      context 'with no valid parameters' do
        it 'should return nil' do
          expect(Hubspot::DealProperties.create_group!({})).to be(nil)
        end
      end

      context 'with mixed parameters' do
        cassette 'deal_create_group'

        it 'should return the valid parameters' do
          response = Hubspot::DealProperties.create_group!(params)
          expect(Hubspot::DealProperties.same?(response, params)).to be true
        end
      end

      context 'with some valid parameters' do
        cassette 'deal_create_group_some_params'

        let(:sub_params) { params.select { |k, _| k != 'displayName' } }

        it 'should return the valid parameters' do
          params['name'] = "ff_group_#{SecureRandom.hex}"
          response       = Hubspot::DealProperties.create_group!(sub_params)
          expect(Hubspot::DealProperties.same?(response.except("name"), sub_params.except("name"))).to be true
        end
      end
    end

    describe '.update_group!' do
      context 'with no valid parameters' do

        it 'should return nil ' do
          expect(Hubspot::DealProperties.update_group!(params['name'], {})).to be(nil)
        end
      end

      context 'with mixed parameters' do
        cassette 'deal_update_group'

        it 'should return the valid parameters' do
          params['displayName'] = 'Test Group OneA'

          response = Hubspot::DealProperties.update_group!(params['name'], params)
          expect(Hubspot::DealProperties.same?(response, params)).to be true
        end
      end

    end

    describe '.delete_group!' do
      let(:name) { params['name'] }

      context 'with existing group' do
        cassette 'deal_delete_group'

        it 'should return nil' do
          expect(Hubspot::DealProperties.delete_group!(name)).to eq(nil)
        end
      end

      context 'with non-existent group' do
        cassette 'deal_delete_non_group'

        it 'should raise an error' do
          expect { Hubspot::DealProperties.delete_group!(name) }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end
  end
end
