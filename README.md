# HubSpot REST API wrappers for ruby

Wraps the HubSpot REST API for convenient access from ruby applications.

Documentation for the HubSpot REST API can be found here: https://developers.hubspot.com/docs/endpoints

## Disclaimer

This gem is a fork of the unofficial [hubspot-ruby](https://github.com/HubspotCommunity/hubspot-ruby) gem which is unfortunately not maintained anymore.

The API has evolved quite a bit and while this is not a drop-in replacement you should feel familiar if you come from `hubspot-ruby`.

This project and the code therein was not created by and is not supported by HubSpot, Inc or any of its affiliates.

## Setup

    gem install hubspot-api-ruby

Or with bundler,

```ruby
gem "hubspot-api-ruby"
```

## Getting Started
This library can be configured to use OAuth or an API key. To find the
appropriate values for either approach, please visit the [HubSpot API
Authentication docs].

Below is a complete list of configuration options with the default values:
```ruby
Hubspot.configure({
  access_token: <ACCESS_TOKEN>,
  base_url: "https://api.hubapi.com",
  portal_id: <PORTAL_ID>,
  logger: Logger.new(nil),
  client_id: <CLIENT_ID>,
  client_secret: <CLIENT_SECRET>,
  redirect_uri: <REDIRECT_URI>,
  read_timeout: nil,
  open_timeout: nil,
  # read_timeout and open_timeout are expressed in seconds and passed to HTTParty
  hapikey: <HAPIKEY>,
})
```

If you're new to using the HubSpot API, visit the [HubSpot Developer Tools] to
learn about topics like "what's a portal id?" and creating a testing
environment.

[HubSpot API Authentication Docs]: https://developers.hubspot.com/docs/methods/auth/oauth-overview
[HubSpot Developer Tools]: https://developers.hubspot.com/docs/devtools

## Authentication with a private app access token

To set the HubSpot access token, run the following:
```ruby
Hubspot.configure(access_token: 'YOUR_ACCESS_TOKEN')
```

Note: some APIs require the portal ID to be set.

```ruby
Hubspot.configure(access_token: 'YOUR_ACCESS_TOKEN', portal_id: 'YOUR_PORTAL_ID')
```

[To learn how to create and manage private apps and access tokens, click here.](https://developers.hubspot.com/docs/api/private-apps)

## Authentication with OAuth 2.0

Configure the library with the client ID and secret from your [HubSpot App](https://developers.hubspot.com/docs/faq/how-do-i-create-an-app-in-hubspot)

```ruby
Hubspot.configure(
    client_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    client_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    redirect_uri: "https://myapp.com/oauth")
```

To initiate an OAuth connection to your app, create a URL with the required scopes:

```ruby
Hubspot::OAuth.authorize_url(["contacts", "content"])
```

After the user accepts the scopes and installs the integration with their HubSpot account, they will be redirected to the URI requested with the query parameter `code` appended to the URL. `code` can then be passed to HubSpot to generate an access token:

```ruby
Hubspot::OAuth.create(params[:code])
```

To use the returned `access_token` string for authentication, you'll need to update the configuration:

```ruby
Hubspot.configure(
    client_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    client_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    redirect_uri: "https://myapp.com/oauth",
    access_token: access_token)
```

Now all requests will use the provided access token when querying the API:

```ruby
Hubspot::Contact.all
```

### Refreshing the token

When you create a HubSpot OAuth token, it will have an expiration date given by the `expires_in` field returned from the create API. If you with to continue using the token without needing to create another, you'll need to refresh the token:

```ruby
Hubspot::OAuth.refresh(refresh_token)
```

### A note on OAuth credentials

At this time, OAuth tokens are configured globally rather than on a per-connection basis.

## Authentication with an API key

NOTE: API keys are deprecated. [Read more here](https://developers.hubspot.com/changelog/upcoming-api-key-sunset) and [find out how to migrate to private apps there](https://developers.hubspot.com/docs/api/migrate-an-api-key-integration-to-a-private-app).

To set the HubSpot API key, aka `hapikey`, run the following:
```ruby
Hubspot.configure(hapikey: "YOUR_API_KEY")
```

If you have a HubSpot account, you can find your API key by logging in and
visiting: https://app.hubspot.com/keys/get

## Usage

Classes have been created that map to Hubspot resource types and attempt to abstract away as much of the API specific details as possible. These classes generally follow the [ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) pattern and general Ruby conventions. Anyone familiar with [Ruby On Rails](https://rubyonrails.org/) should find this API closely maps with familiar concepts.

### Example

https://github.com/lounna-sas/hubspot-api-ruby/wiki

## Resource types

**Note:** These are the currently defined classes the support the new resource API. This list will continue to grow as we update other classes. All existing classes will be updated prior to releasing v1.0.

* Contact -> Hubspot::Contact
* Company -> Hubspot::Company

## Contributing to hubspot-api-ruby

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

### Testing

This project uses [VCR] to test interactions with the HubSpot API.
VCR records HTTP requests and replays them during future tests.

To run the tests, run `bundle exec rake` or `bundle exec rspec`.

By default, the VCR recording mode is set to `:none`, which allows recorded
requests to be re-played but raises for any new request. This prevents the test
suite from issuing unexpected HTTP requests.

Some requests require to be done on a live hubspot portal, you can set the `HUBSPOT_ACCESS_TOKEN` and `HUBSPOT_PORTAL_ID` environement variables, for example inside a `.env.test` file :

```
HUBSPOT_ACCESS_TOKEN=xxxx
HUBSPOT_PORTAL_ID=yyyy
HUBSPOT_HAPI_KEY=zzzz
```

To add a new test or update a VCR recording, run the test with the `VCR_RECORD_MODE`
environment variable, for instance:

```sh
VCR_RECORD_MODE=new_episodes bundle exec rspec spec
```

[VCR]: https://github.com/vcr/vcr
