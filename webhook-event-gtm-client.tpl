___INFO___

{
  "type": "CLIENT",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Webhook to Event Client",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Generic webhook endpoint for translating a webhook into a single event and assigning webhook data to event parameters.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "Usage",
    "displayName": "The Generic Webhook Client lets you search JSON from webhooks pointing at the request path specified in this client on your tag manager\u0027s server for JSON keys matching the Input Key and then map those values to the Output Key. \n\nDefault lets you set a default parameter where matching fails. You can combine Default with an empty Input Key and a unique Output Key to hard-code values."
  },
  {
    "type": "TEXT",
    "name": "webhookPath",
    "displayName": "Request Path",
    "simpleValueType": true,
    "help": "Combine the value for request path (/mypath) with the domain that you are hosting GTM on (ie https://gtm.mydomain.com/mypath) and enter this as the webhook destination on the site where it originates"
  },
  {
    "type": "TEXT",
    "name": "allowedOrigins",
    "displayName": "Allowed Origins",
    "simpleValueType": true,
    "help": "Comma separated list (ie https://webhookorigindomain1.com,http://webhookorigindomain2.com)"
  },
  {
    "type": "CHECKBOX",
    "name": "disableOriginCheck",
    "checkboxText": "Disable Origin Check",
    "simpleValueType": true,
    "help": "Not recommended"
  },
  {
    "type": "PARAM_TABLE",
    "name": "parameters",
    "displayName": "Map Event Parameters",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "inputKey",
          "displayName": "Input Key",
          "simpleValueType": true
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "TEXT",
          "name": "outputKey",
          "displayName": "Output Key",
          "simpleValueType": true,
          "help": "One Output Key should match \"event_name\" in most cases."
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "TEXT",
          "name": "defaultVal",
          "displayName": "Default",
          "simpleValueType": true,
          "help": "Hard-code a value by entering a Default here with an empty Input Key."
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "RADIO",
          "name": "dataType",
          "displayName": "Data Type",
          "radioItems": [
            {
              "value": "string",
              "displayValue": "string"
            },
            {
              "value": "num",
              "displayValue": "num"
            }
          ],
          "simpleValueType": true
        },
        "isUnique": false
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const claimRequest = require('claimRequest');
const getRequestBody = require('getRequestBody');
const getRequestHeader = require('getRequestHeader');
const getRequestPath = require('getRequestPath');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const returnResponse = require('returnResponse');
const runContainer = require('runContainer');
const setResponseBody = require('setResponseBody');
const setResponseHeader = require('setResponseHeader');
const setResponseStatus = require('setResponseStatus');

const log = msg => {
  logToConsole('Webhook: ' + msg);
};

// Helper
const sendResponse = () => {
  // Disable for testing curl requests from local machine
  log("Sending response");
  // Prevent CORS errors
  const origin = getRequestHeader('origin');
  if (origin) {
    setResponseHeader('Access-Control-Allow-Origin', origin);
    setResponseHeader('Access-Control-Allow-Credentials', 'true');
  }
  returnResponse();
};


function findVal(object, key , def ) {
  // Empty key returns the default value
  if(key === ""){ 
    return def; 
  }
  var value;
  log("Searching for key: " + key + "\n in object: " + JSON.stringify(object) );
  for(let k in object) {
      log("k variable: " + k);
      if ( object.hasOwnProperty(k) && k === key ){
          log("Matched value: " + JSON.stringify(object[k]) );
          value = object[k];
          return value;
      }  
      if (object[k] && typeof(object[k]) === 'object' ) {      
          log("Found internal object: " + JSON.stringify(object[k]));
          findVal(object[k], key);
      }
    }
  return def;
}

if (getRequestPath() === data.webhookPath ) {
  // Claim the requst
  claimRequest();
  log('Webhook request claimed on ' + getRequestPath() );
  var statusCode = 200;
  if ( getRequestHeader('content-type') !== 'application/json' ){
    log("Error: content-type must be application/json");
    statusCode = 415;
  } else { log("Content type matches application/json"); }
  const event = {};
  const webhookData = JSON.parse(getRequestBody());
  const parameters = data.parameters;
  data.parameters.forEach((parameter) =>{
    //match inputKey to input JSON and map to outputKey
    var inputKey = parameter.inputKey;
    var outputKey = parameter.outputKey;
    var defaultVal = parameter.defaultVal;

    log("inputKey: " + inputKey);
    log("outputKey: " + outputKey);
    log("defaultVal: " + defaultVal);

     event[outputKey] = findVal(webhookData, inputKey, defaultVal );
  });
  log("Running container with event: " + JSON.stringify(event));
  runContainer(event, () => sendResponse());
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "content-type"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "bodyAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "pathAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "writeStatusAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "writeHeadersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "writeBodyAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "writeHeaderWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "content-type"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "cache-control"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "pragma"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "expires"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Access-Control-Allow-Origin"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Access-Control-Allow-Credentials"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Flat JSON Input
  code: |-
    const mockData = {
      parameters: [{"inputKey":"eventName","outputKey":"event_name","defaultVal":"default event"},{"inputKey":"product","outputKey":"product","defaultVal":"default product"}],
      webhookPath: '/testPath',
    };

    mock('getRequestBody', '{\"eventName\": \"registrant.added\",\"eventVersion\": \"1.0.0\",\"callbackUrl\": \"https://en1vd6q5jmpqb.x.pipedream.net\",\"product\": \"g2w\",\"webhookKey\": \"dff781bc-fake-4361-81ff-d5e9861fb0e1\",\"state\": \"INACTIVE\",\"createTime\": \"2019-03-14T18:06:30.365Z\"}'  );



    // Call runCode to run the template's code.
    runCode(mockData);
    assertApi('claimRequest').wasCalled();
    // assertApi('getRequestHeader').wasCalledWith('content-type','application/json');
    assertApi('getRequestHeader').wasCalledWith('origin');
    assertApi('setResponseHeader').wasCalledWith('Access-Control-Allow-Origin', 'origin');
    assertApi('setResponseHeader').wasCalledWith('Access-Control-Allow-Credentials', 'true');
    assertApi('returnResponse').wasCalled();
- name: Missing JSON Key Returns Default Val
  code: |-
    const mockData = {
      parameters: [{"inputKey":"eventName","outputKey":"event_name","defaultVal":"default event"},{"inputKey":"product_no_match","outputKey":"product","defaultVal":"goToWebhinar"}],
      webhookPath: '/testPath',
    };

    mock('getRequestBody', {"eventName": "registrant.added","eventVersion": "1.0.0","callbackUrl": "https://en1vd6q5jmpqb.x.pipedream.net","product": "g2w","webhookKey": "dff781bc-fake-4361-81ff-d5e9861fb0e1","state": "INACTIVE","createTime": "2019-03-14T18:06:30.365Z"}  );
    mock('getRequestPath', "/testPath");
    mock('getRequestHeader', header => {return "application/json";});


    // Call runCode to run the template's code.
    runCode(mockData);
- name: Nested JSON Input
  code: |-
    const mockData = {
      parameters: [{"inputKey":"eventName","outputKey":"event_name","defaultVal":"default event"},{"inputKey":"product","outputKey":"product","defaultVal":"goToWebhinar"}],
      webhookPath: '/testPath',
    };

    mock('getRequestBody', {"_embedded": {"webhooks": [{"eventName": "registrant.added","eventVersion": "1.0.0","callbackUrl": "https://en1vd6q5jmpqb.x.pipedream.net","product": "g2w","webhookKey": "dff781bc-fake-4361-81ff-d5e9861fb0e1","state": "INACTIVE","createTime": "2019-03-14T18:06:30.365Z"}]}} );
    mock('getRequestPath', "/testPath");
    mock('getRequestHeader', header => {return "application/json";});

    const result = runCode(mockData);
- name: Non-JSON Content Fails
  code: |-
    const mockData = {
      parameters: [{"inputKey":"eventName","outputKey":"event_name","defaultVal":"default event"},{"inputKey":"product","outputKey":"product","defaultVal":"default product"}],
      webhookPath: '/testPath',
    };

    mock('getRequestBody', {"eventName": "registrant.added","eventVersion": "1.0.0","callbackUrl": "https://en1vd6q5jmpqb.x.pipedream.net","product": "g2w","webhookKey": "dff781bc-fake-4361-81ff-d5e9861fb0e1","state": "INACTIVE","createTime": "2019-03-14T18:06:30.365Z"}  );
    mock('getRequestPath', "/testPath");
    mock('getRequestHeader', header => {return "application/json";});


    // Call runCode to run the template's code.
    runCode(mockData);

    // assertApi('returnResponse', status).wasCalledWith(415);
- name: Empty JSON inputKey Defaults
  code: |-
    const mockData = {
      parameters: [{"inputKey":"","outputKey":"event_name","defaultVal":"default event"}],
      webhookPath: '/testPath',
    };

    mock('getRequestBody', {"eventName": "registrant.added","eventVersion": "1.0.0","callbackUrl": "https://en1vd6q5jmpqb.x.pipedream.net","product": "g2w","webhookKey": "dff781bc-fake-4361-81ff-d5e9861fb0e1","state": "INACTIVE","createTime": "2019-03-14T18:06:30.365Z"}  );
    mock('getRequestPath', "/testPath");
    mock('getRequestHeader', header => {return "application/json";});


    // Call runCode to run the template's code.
    runCode(mockData);
setup: |-
  mock('getRequestHeader', header => {
    if (header === 'origin') return 'https://test-origin.com';
    if (header === 'content-type') return 'application/json';
    if (header === 'x-gtm-server-preview') return 'ZW52LTN8eVFORWZuZGlSMkZxQmVYSUdPSkhHUXwxODAwYTZiOWZhYzg3MDQyMGI5YjY=';
    fail('invalid argument passed to getRequestHeader');
  });
  mock('getRequestPath', '/testPath');


___NOTES___

Created on 9/30/2022, 8:24:46 AM


