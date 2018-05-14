#!/bin/bash

set -o errexit

cd $SCRIPTS_FOLDER

# Poll until we can successfully connect to MongoDB
echo 'Connecting to MongoDB...'
node <<- 'EOJS'
require('p-wait-for')(function() {
	return new Promise(function (resolve) {
		require('mongodb').MongoClient.connect(process.env.MONGO_URL, function(err, client) {
			const successfullyConnected = err == null;
			if (successfullyConnected) {
				client.close();
			}
			resolve(successfullyConnected);
		});
	});
}, 1000);
EOJS

echo 'Starting app...'
cd $APP_BUNDLE_FOLDER/bundle

exec "$@"
