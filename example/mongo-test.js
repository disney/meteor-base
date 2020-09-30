console.log(process.env.MONGO_URL);
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
