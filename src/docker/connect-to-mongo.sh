#!/bin/bash

set -o errexit

cd $SCRIPTS_FOLDER

if [ -n "${MONGO_URL:-}" ]; then # Check for MongoDB connection if MONGO_URL is set
	# Poll until we can successfully connect to MongoDB
	echo 'Connecting to MongoDB...'
	node <<- 'EOJS'
	const mongoDb = require("mongodb");
	const mongoClient = new mongoDb.MongoClient(process.env.MONGO_URL, {
		useUnifiedTopology: true,
	});
	setInterval(function () {
		mongoClient.connect(function (err, client) {
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
fi
