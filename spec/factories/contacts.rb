# frozen_string_literal: true

FactoryBot.define do
  factory :contact, class: 'Hubspot::Contact' do
    to_create { |instance| instance.save }

    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email do
      Faker::Internet.email(name: "#{Time.new.to_i.to_s[-5..-1]}#{(0..3).map { rand(65..90).chr }.join}",
                            domain: 'hubspot.com')
    end
  end
end
