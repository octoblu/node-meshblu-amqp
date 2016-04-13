# node-meshblu-amqp
AMQP client library for Meshblu

[![Build Status](https://travis-ci.org/octoblu/.svg?branch=master)](https://travis-ci.org/octoblu/)
[![Code Climate](https://codeclimate.com/github/octoblu//badges/gpa.svg)](https://codeclimate.com/github/octoblu/)
[![Test Coverage](https://codeclimate.com/github/octoblu//badges/coverage.svg)](https://codeclimate.com/github/octoblu/)
[![npm version](https://badge.fury.io/js/.svg)](http://badge.fury.io/js/)
[![Gitter](https://badges.gitter.im/octoblu/help.svg)](https://gitter.im/octoblu/help)

### Install
```bash
npm install meshblu-xmpp
```

### Example Usage

#### Set-up
```js
var meshblu = require('meshblu-amqp');

var config = {
  'hostname': 'meshblu-amqp.octoblu.com',
  'port': 5672,
  'uuid': '',
  'token': ''
}

var conn = new meshblu(config);

conn.connect(function(data){

}); // conn.connect
```

#### Send Message
```js
conn.message({"devices": ["*"], "payload": "duuude"}, function(result){
  console.log('Send Message: ', result);
});
```

#### On Message
```js
// Message handler
conn.on('message', function(message){
  console.log('Message Received: ', message);
});

```

#### Create Session Token
```js
conn.createSessionToken(config.uuid, {"createdAt": Date.now()},
function(err, result){
  console.log('Create Session Token: ', result);
});
```

#### Check status of Meshblu
```js
conn.status(function(err, result){
  console.log('Status:', result);
});
```

#### Whoami
```js
conn.whoami(function(err, result){
  console.log('Whoami: ', result);
});
```

#### Update
```js
// Update a specific device - you can add arbitrary json
conn.update(config.uuid, { "$set": {"type": "device:generic"}}, function(err, device){
  console.log('Update Device:', device);
});
```

#### Register
```js
// Register a new device
conn.register({"type": "device:generic"}, function(err, device){
  console.log('Register Device: ', device);
});
```

#### Subscribe
```js
// Subscribe to your own messages to enable recieving them
// conn.unsubscribe takes the same arguments
var subscription = {
  "subscriberUuid" : config.uuid,
  "emitterUuid": config.uuid,
  "type": 'message.received'
};
conn.subscribe(config.uuid, subscription, function(err, result){
  console.log('Subscribe: ', result);
});
```

#### Search Devices
```js
// Search for devices by a query
var query = {
  "type": "device:generic"
};
conn.searchDevices(config.uuid, query, function(err, result){
  console.log('Search Devices: ', result);
  console.log(err);
});
```

## Testing
You'll need to add some users to your test rabbitmq instance

```shell
rabbitmqctl add_user meshblu judgementday
rabbitmqctl set_permissions meshblu ".*" ".*" ".*"
rabbitmqctl add_user some-uuid some-token
rabbitmqctl set_permissions some-uuid '^(amq\.gen.*|amq\.default|^some-uuid.*)$' '.*' '.*'
```
