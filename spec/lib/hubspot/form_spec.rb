describe Hubspot::Form do
  let(:example_form_hash) do
    VCR.use_cassette('form_example') do
      guid = Hubspot::Form.all.first.guid
      headers = { Authorization: "Bearer #{ENV.fetch('HUBSPOT_ACCESS_TOKEN')}" }
      HTTParty.get("https://api.hubapi.com#{Hubspot::Form::FORMS_PATH}/#{guid}", headers: headers).parsed_response
    end
  end

  let(:create_params) do
    {
      name: "Demo Form #{SecureRandom.hex}",
      action: '',
      method: 'POST',
      cssClass: 'hs-form stacked',
      redirect: '',
      submitText: 'Sign Up',
      followUpId: '',
      leadNurturingCampaignId: '',
      notifyRecipients: '',
      embeddedCode: ''
    }
  end

  describe '#initialize' do
    subject { Hubspot::Form.new(example_form_hash) }

    it { should be_an_instance_of Hubspot::Form }
    its(:guid) { should be_a(String) }
    its(:properties) { should be_a(Hash) }
  end

  describe '.all' do
    cassette 'find_all_forms'

    it 'returns all forms' do
      forms = Hubspot::Form.all

      form = forms.first
      expect(form).to be_a(Hubspot::Form)
    end
  end

  describe '.find' do
    cassette 'form_find'
    subject { Hubspot::Form.find(Hubspot::Form.all.first.guid) }

    context 'when the form is found' do
      it { should be_an_instance_of Hubspot::Form }
      its(:fields) { should_not be_empty }
    end

    context 'when the form is not found' do
      it 'raises an error' do
        expect { Hubspot::Form.find(-1) }.to raise_error(Hubspot::NotFoundError)
      end
    end
  end

  describe '.create' do
    subject { Hubspot::Form.create!(create_params) }

    context 'with all required parameters' do
      cassette 'create_form'

      it { should be_an_instance_of Hubspot::Form }
      its(:guid) { should be_a(String) }
    end

    context 'without all required parameters' do
      cassette 'fail_to_create_form'

      it 'raises an error' do
        expect { Hubspot::Form.create!({}) }.to raise_error(Hubspot::RequestError)
      end
    end
  end

  describe '#fields' do
    context 'returning all the fields' do
      cassette 'fields_among_form'

      let(:form) { Hubspot::Form.new(example_form_hash) }

      it 'returns by default the fields property if present' do
        fields = form.fields
        fields.should_not be_empty
      end

      it 'updates the fields property and returns it' do
        fields = form.fields(bypass_cache: true)
        fields.should_not be_empty
      end
    end

    context 'returning an uniq field' do
      cassette 'field_among_form'

      let(:form) { Hubspot::Form.new(example_form_hash) }
      let(:field_name) { form.fields.first['name'] }

      it 'returns by default the field if present as a property' do
        field = form.fields(only: field_name)
        expect(field).to be_a(Hash)
        expect(field['name']).to be == field_name
      end

      it 'makes an API request if specified' do
        field = form.fields(only: field_name, bypass_cache: true)
        expect(field).to be_a(Hash)
        expect(field['name']).to be == field_name
      end
    end
  end

  describe '#submit' do
    cassette 'form_submit_data'

    let(:form) { Hubspot::Form.all.first }

    context 'with a valid portal id' do
      before do
        Hubspot.configure(access_token: ENV.fetch("HUBSPOT_ACCESS_TOKEN"), portal_id: ENV.fetch("HUBSPOT_PORTAL_ID"))
      end

      it 'returns true if the form submission is successful' do
        params = {}
        result = form.submit(params)
        result.should be true
      end
    end

    context 'with an invalid portal id' do
      before do
        Hubspot.configure(access_token: ENV.fetch("HUBSPOT_ACCESS_TOKEN"), portal_id: "xxx")
      end

      it 'returns false in case of errors' do
        params = { unknown_field: :bogus_value }
        result = form.submit(params)
        result.should be false
      end
    end

    context 'when initializing Hubspot::Form directly' do
      let(:f) { Hubspot::Form.new('guid' => form.guid) }

      before do
        Hubspot.configure(access_token: ENV.fetch("HUBSPOT_ACCESS_TOKEN"), portal_id: ENV.fetch("HUBSPOT_PORTAL_ID"))
      end

      it 'returns true if the form submission is successful' do
        params = {}
        result = f.submit(params)
        result.should be true
      end
    end
  end

  describe '#update!' do
    cassette 'form_update'

    new_name = "updated form name #{SecureRandom.hex}"
    redirect = 'http://hubspot.com'

    let(:form) { Hubspot::Form.create!(create_params) }
    let(:params) { { name: new_name, redirect: redirect } }
    subject { form.update!(params) }

    it 'updates properties' do
      should be_an_instance_of Hubspot::Form
      subject.properties['name'].should start_with('updated form name ')
      subject.properties['redirect'].should be == redirect
    end
  end

  describe '#destroy!' do
    cassette 'form_destroy'

    let(:form) { Hubspot::Form.create!(create_params) }
    subject { form.destroy! }
    it { should be true }

    it 'should be destroyed' do
      subject
      form.destroyed?.should be true
    end
  end
end
