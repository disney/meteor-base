#!/bin/bash

set -o errexit

cd $SCRIPTS_FOLDER

if [ -n "${MONGO_URL:-}" ]; then # Check for MongoDB connection if MONGO_URL is set
	# Poll until we can successfully connect to MongoDB
	echo 'Connecting to MongoDB...'
	node <<- 'EOJS'
	const mongoClient = require('mongodb').MongoClient;
	setInterval(async function() {
		let client;
		try {
			client = await mongoClient.connect(process.env.MONGO_URL);
			console.log('Successfully connected to MongoDB');
			await client.close();
			process.exit(0);
		} catch (err) {
			console.error(err);
		}
	}, 1000);
	EOJS
fi
