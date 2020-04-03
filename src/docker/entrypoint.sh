#!/bin/bash

set -o errexit

cd $SCRIPTS_FOLDER

# Poll until we can successfully connect to MongoDB
echo 'Connecting to MongoDB...'
node <<- 'EOJS'
// If mongodb doesn't exist do not attempt waiting for it.
try { require.resolve('mongodb'); } catch { process.exit(0); };

// Similarly, if MONGO_URL is not set, do not wait its startup.
if (typeof process.env.MONGO_URL === 'undefined') process.exit(0);

const mongoClient = require('mongodb').MongoClient;
setInterval(function() {
	mongoClient.connect(process.env.MONGO_URL, function(err, client) {
		if (client) {
			client.close();
		}
		if (err) {
			console.error(err);
		} else {
			process.exit(0);
		}
	});
}, 1000);
EOJS

echo 'Starting app...'
cd $APP_BUNDLE_FOLDER/bundle

exec "$@"
