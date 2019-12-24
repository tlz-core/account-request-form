AWS.config.region = "${aws_region}";
const identityPoolId = "${identity_pool}";
const dynamoDBId = "${dynamoDBTable}";


/**
 *
 * id == Key
 * appName == Range
 */
var timeNow = new Date()
timeNow = timeNow.getTime().toString()
var cognitoidentity = new AWS.CognitoIdentity()
var params = {
  IdentityPoolId: identityPoolId
}

function buildDataPayload(formJSON, requestId) {
  const data = {
    Item: {
      "id": {
        S: formJSON.InputAccountEmail
      },
      "accountEmail": {
        S: formJSON.InputEmail
      },
      "appName": {
        S: formJSON.InputAppName
      },
      "cloudProvider": {
        S: formJSON.InputVendor
      },
      "primaryRegion": {
        S: formJSON.InputPrimaryRegion
      },
      "primaryVpcCidr": {
        S: formJSON.InputPrimaryIP
      },
      "secondaryVpcCidr": {
        S: formJSON.InputSecondaryIP
      },
      "accountType": {
        S: formJSON.InputAccountType
      },
      "envType": {
        S: formJSON.InputAccountSubType
      },
      "responsible": {
        S: formJSON.InputResponsible
      },
      "lob": {
        S: formJSON.InputLineOfBusiness
      },
      "accountPrefix": {
        S: formJSON.InputAccountPrefix
      },
      "servicenowCase": {
        S: formJSON.InputServiceNow
      },
      "costCenter": {
        S: formJSON.InputCostCenter
      },
      "securityContact": {
        S: formJSON.InputInfoSecEmail
      },
      "reqId": {
        S: requestId
      },
      "createdAt": {
        S: this.timeNow
      }
    },
    TableName: dynamoDBId
  };
  return data
}

function submitForm(formJSON, callback) {
  if (typeof (formJSON) === "string") {
    formJSON = JSON.parse(formJSON);
  }

  cognitoidentity.getId(this.params, function (err, data) {
    if (!err) {
      AWS.config.credentials = new AWS.CognitoIdentityCredentials({
        IdentityPoolId: identityPoolId,
        IdentityId: data.IdentityId
      });

      const dynamodb = new AWS.DynamoDB();
      const requestId = formJSON.InputAccountEmail
      params = buildDataPayload(formJSON, requestId);
      const paramsPrecheck = {
        Key: {
          "id": {
            S: formJSON.InputAccountEmail
          }
        },
        TableName: dynamoDBId
      };

      dynamodb.getItem(paramsPrecheck, function (err, data) {
        if (!err) {
          dynamodb.putItem(params, function (err, data) {
            if (err) {
              callback("Unable to insert record: " + err);
            } else {
              callback(null, requestId);
            }
          });
        }
      });
    }
  });
}

function handleOutput(resultOutput, htmlBody) {
  output.setAttribute("class", resultOutput);
  output.innerHTML = htmlBody;
}
