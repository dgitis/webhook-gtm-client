# Webhook-to-Event Server-Side Google Tag Manager Client

This is a generic Google Tag Manager client that lets you map incoming JSON key and values to event parameter names and values.

## Installation

- Download the _webhook-event-gtm-client.tpl_ file.
- In you Server-Side Google Tag Manager container, select _Templates_.
- On the _Templates_ page in the _Client Templates_ section, select _New_.
- In the _Template Editor_, click the three dot icon at the top right of the interface and select _Import_.
- In your browser's upload dialog, select the _webhook-event-gtm-client.tpl_ file.
- The _Templates_ page should populate with information from the Webhook-to-Event Client. To finish the installation, click _Save_.

## Usage

The Webhook-to-Event client template is designed to work with just a single type of webhook in each installation of the webhook. If you working with multiple types of webhook events, you will have to create a separate client from the Webhook-to-Event client template for each type of webhook event.

For example, if you were working with (Drift)[https://devdocs.drift.com/docs/webhook-events-1] and wanted to create new_conversation, new_message, and contact_identified webhooks, you would need to create a separate client for each of those webhooks.

### Request Path

The client will claim any requests to the Request Path field on your server URL. 

You will need to configure your webhook to point at this URL.

For example, if we continue the chat bot example, we would create three different clients with three different request paths.

| Webhook | Example Request Path | Example URL |
|---------|----------------------|-------------|
| new_conversation | new-conversation | https://gtm.mydomain.com/new-conversation |
| new_message | new-message | https://gtm.mydomain.com/new-message |
| contact_identified | contact-identified | https://gtm.mydomain.com/contact-identified |

### Allowed Origins

It is recommended that you restrict your webhook clients to only accept requests from the webhook servers that will be sending requests. Allowed origins accepts comma-separated domains.

For example, `http://drift.com,https://drift.com`.

You can disable the origin check. This is useful when testing your initial setup using curl (see below).

### Mapping Webhook JSON to GTM Variables

This is where you configure the client to look for keys in the webhook JSON and map the value for that key to a GTM variable.

Add a row for each variable you want to create from the source JSON.

The mapping fields are as follows:

- Input Key (optional): this is the key that we search for in the webhook JSON
- Output Key: this will be the Key Path for the GTM Event Data variable that you set up to use the processed webhook data 
- Default (optional): this is the default value when the _Input Key_ is not present
- Data Type: select one of 'string' or 'num' as appropriate

For example, we want to use Drift's contact_identified webhook to create a generate_lead GA4 event.

The webhook JSON, with contact model filled out would look something like this:

```
{
  "orgId": 4488886666,
  "type": "contact_identified",
  "data": {
    "attributes": {
        "email": "swebel@drift.com",
        "events": {},
        "name": "Stephen Webel",
        "socialProfiles": {},
        "tags": [],
        "externalId": 12341243 (sometimes set by external integrations),
        ...
    },
    "createdAt": 1506971031434,
    "id": 349999553
    }
}
```
The client will look through the nested JSON fields until it reaches the first match and returns that value. It will find keys nested within arrays and dictionaries.

We might use the following configurations from the above webhook JSON to pass orgId, email, and id to GTM variables for use in tags.

| Input Key | Output Key | Default | Data Type |
|-----------|------------|---------|-----------|
| orgId | drift_org_id |  | int |
| email | email | | string|
| id | drift_contact_id | | int |

Please take care to comply with any applicable laws when working with personal data like email when configuring this client.

If you want to create a hard-coded value, you would leave the _Input Key_ blank and set an _Output Key_ and _Default_.

For example, we know that our example webhooks come from Drift and we want to map the Drift (contact_identified)[https://devdocs.drift.com/docs/webhook-events-1#contact-email-captured] event to a generate_lead GA4 event. We also use the generate_lead event for leads from other sources, like form fills, so we have a lead_source custom dimension.

To set lead source, we would want to add the following values:

- Input Key: ''
- Output Key: 'lead_source'
- Default: 'drift'
- Data Type: 'string'

This would give us a final configuration that looks like this:

| Input Key | Output Key | Default | Data Type |
|-----------|------------|---------|-----------|
| orgId | drift_org_id |  | int |
| email | email | | string|
| id | drift_contact_id | | int |
|   | lead_source | drift | string |

### Create GTM Variables

To use the Webhook-to-Event client for tags, you will first need to create GTM variables for each row of event parameters.

- For each parameter, create an _Event Data_ variable.
- Set the _Key Path_ field to match the _Output Key_.
- Further name and configure the variable as desired and click _Save_.

### Create a GTM Tag

To finally do something with the data that the webhook client has processed, you will need to create a GTM tag and trigger.

The trigger will be a _Custom_ trigger set to fire on `Client Name equals <name of the client that you configured>`.

Use that trigger to fire your desired tag and map the GTM variables that you created to the desired tag fields.

For example, using the generate_lead event with the example configuration set above, we might create the following GA4 configurations.

*Note that it is against GA4's terms of service to send personal information like email. To actually use this configuration, you would want to minimally add a Variable Template that hashes the email before sending it to GA4.*

- Create a GA4 tag.
- In the _Measurement ID_ field, enter your desired Measurement ID.
- In the _Event Name_ field, enter *generate_lead*.
- In the _Parameters to Add / Edit_ section of _Event Parameters_, select _Add Row_ and set the _Name_ to *lead_source* and select the lead source variable you created for _Value_.
- In the _Properties to Add / Edit_ section of _User Properties_, select _Add Row_ and map the _Name_ and _Value_ fields to your drift_org_id, email, and drift_contact_id variables.
- In the _Triggering_ section, add the trigger that you just created.

Note that in order for this setup to work, you will likely need to set either the hashed email or drift_contact_id variables as the user_id since GA4 requires a user_id or client_id.

## Testing

When setting up this client, it is easy to get a sample JSON payload for the webhook that you are working with and use 'curl' commands to send test events. You will need to open the terminal on a Linux machine, Linux, Mac OSX, or install WSL in Windows and modify the following curl command.

```
curl 'https://gtm.testsite.com/testPath' -H 'x-gtm-server-preview: keystring' -H "Content-Type: application/json" -d'{"eventName": "test_event","eventParam1": "test_param"}' 
```

- Change the server path to match the server path that you configured.
- Add the (x-gtm-server-preview)[https://www.simoahava.com/gtmtips/preview-server-side-google-tag-manager/] header.
- Replace everything in curly braces with your JSON payload. Be careful about the type of quotes enclosing your JSON. You may need to switch the single quotes to double quotes or edit your JSON file.
- Check the _Disable origin check_ setting in your client.

## Notes

The Webhook-to-Event client template does not work with webhooks that send multiple events in one payload. It will only get the first set of values.