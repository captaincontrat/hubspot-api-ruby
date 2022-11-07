## 0.13.0

  * BREAKING: requires ruby 2.7+, as we're not testing against olders rubies. #11 + #12

## 0.12.0

  * Added Resource#properties reader (thanks @ur5us!) #10

## 0.11.0

  * Get a single property and a single property group (thanks @sammyd!) #9

## 0.10.0

  * API keys (`hapikey`) are deprecated. Please use `access_token`s. #7

  * Breaking change: removed previously deprecated methods `Hubspot::Utils.dump_properties` and `Hubspot::Utils.restore_properties`

## 0.9.0

  * Governance update: this gem is now maintained by the team over at @captaincontrat + @Intrepidd from @ecotable

  * Testing against modern ruby & activesupport versions #6

  * Breaking change regarding `Hubspot::Association`, for example :

    before :
    `Hubspot::Association.batch_create([{ from_id: 1, to_id: 2, definition_id: Hubspot::Association::COMPANY_TO_CONTACT }])`

    now: `Hubspot::Association.batch_create("Company", "Contact", [{from_id: 1, to_id: 2}]])` #6

  * Removed unsupported Hubspot::`ContactList#refresh` method #6

  * Added `Hubspot::NotFoundError` which inherits from `NotFoundError` and that is raised when the error code is 404 for finer exception handling

## Up until 0.8.1 (December 31, 2019)

* [#168] `Hubspot.configure` will raise when given none or multiple ways to
  authenticate with the HubSpot API.

[#168]: https://github.com/adimichele/hubspot-ruby/pull/168

* [#167] Updates the endpoints referenced in `CompanyProperties` to match the new
  HubSpot CompanyProperty endpoints.

[#167]: https://github.com/adimichele/hubspot-ruby/pull/167

* [#166] Updates the endpoints referenced in `ContactProperties` to match the new
  HubSpot ContactProperty endpoints.

* Other history entries have not been logged

[#166]: https://github.com/adimichele/hubspot-ruby/pull/166

## 0.6.1 (November 29, 2018)

* [#148] Deprecate the use of the hubspot rake tasks. Deprecating these tasks
  includes deprecating the use of `Hubspot::Utils.dump_properties` and
  `Hubspot::Utils.restore_properties`.

[#148]: https://github.com/adimichele/hubspot-ruby/pull/148

* [#148] Fix backwards compatibility to ensure users can access the hubspot rake
  tasks

[#148]: https://github.com/adimichele/hubspot-ruby/pull/148

## 0.6.0 (November 28, 2018)

* [#141] Add `HubSpot` as an alias of `Hubspot`

[#141]: https://github.com/adimichele/hubspot-ruby/pull/140

* [#134] Add support to find recently created or recently modified Companies

[#134]: https://github.com/adimichele/hubspot-ruby/pull/134
