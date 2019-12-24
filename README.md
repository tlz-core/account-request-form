# Account Request Form

This application will provide an S3 Hosted website hosting a form that populates a DynamoDB table (specified in 00_Vars.tf).  This table can then be monitored to trigger downstream workflows like that used to onboard new accounts. Please keep in mind that network access is restricted to only allow access to IST VPN IP address.


## Pre-reqs

* Terraform
* If you cannot or do not want to use this module, then update ``local.whitelist_ips`` to point to ``var.account-request-whitelist-ips`` and set the value of this      variable list to whatever CIDR values are appropriate.

Terraform is leveraged to deploy this application.

* Configure

The 00_Vars.tf can be adjusted as required to configure AWS accounting configuration and preferences.

## Installation

* Step 1 - Clone this repo

* Step 2 - Initialize Terraform

```bash

terraform init

```

* Step 3 - Establish credentials

```bash

gimme-aws-creds -k

```

* Step 4 - deploy

```bash

terraform apply

```

### Vanity URL and SSL (i.e. "arf")

To make this thing friendlier for customers, we have added the option to deploy a friendly FQDN to front the s3 bucket (via CloudFront) and do fancy things like TLS offloading.

In order to utilize this, there will need to be a route53 hosted zone deployed in the target AWS account.

If you wish to to deploy this feature:
1. set ``var.add_vanity_url`` to true (default: false)
1. set ``var.hosted_zone`` to the name of the hosted zone in your account (minus the trailing '.' i.e. example.com)
1. Enjoy a life where you don't need to recall some inscrutable s3 website_endpoint

## Modification

Modification to the form will likely require 2 maybe 3 steps.  
  1) Edit the `index.html` input fields.  Add, modify or delete the html inputs.
  2) Edit the `app.js.tpl`.  This puts together the payload that gets submitted to the dynamodb.
  3) Edit the `index.html` jquery if you need html event handling

#### HTML

To add or remove fields from the form, you can freely update the HTML present in index.html.  Keep in mind that all of the input fields are expected to have an id attribute and a corresponding label.

Example:

```html
<label for="InputNewFormField">Input New Form Field</label>
<input value='Input Value' placeholder='Input Value Placeholder' type="text" id="InputNewFormField" required/>
```

#### data payload

When any fields are added or removed, app.js should requires an update to reflect the change in the data structure being sent to DynamoDB.  Adjust the buildDataPayload() function to reflect the additions and deletions.

example (form input with id of `InputEmail` is mapped to the Dynamo `email` field):

```javascript  
function buildDataPayload(formJSON) {
  {
    Item: {
     "new": {
       S: formJSON["InputNewFormField"]
      }
    },
    TableName: "${dynamoDBTable}"
   };
}
```

#### jquery

update the necessary jquery methods.

```javascript
<script type="text/javascript">
  $("#InputAccountType").change(function () {
    $("#InputLineOfBusiness").attr("disabled", "true");
    $("#InputPrimaryIP").val("192.168.0.0/16")
  }
</script>
```

### Validation

Verify that both steps have been implemented onto the web form and push the changes to GitHub. These changes should automatically be applied to the webform if the terraform plan completes successfully.
