# The tag here should match the Meteor version of your app, per .meteor/release
FROM geoffreybooth/meteor-base:2.11.0 AS bundler

USER node:node

# Copy app package.json and package-lock.json into container
COPY --chown=node:node ./app/package*.json $APP_SOURCE_FOLDER/

RUN bash $SCRIPTS_FOLDER/build-app-npm-dependencies.sh

# Copy app source into container
COPY --chown=node:node ./app $APP_SOURCE_FOLDER/

RUN bash $SCRIPTS_FOLDER/build-meteor-bundle.sh


# Use the specific version of Node expected by your Meteor release, per https://docs.meteor.com/changelog.html; this is expected for Meteor 2.11.0
FROM node:14.21.3-alpine

ENV NODE_HOME /home/node
ENV APP_BUNDLE_FOLDER $NODE_HOME/bundle
ENV SCRIPTS_FOLDER $NODE_HOME/docker

# Runtime dependencies; if your dependencies need compilation (native modules such as bcrypt) or you are using Meteor <1.8.1, use app-with-native-dependencies.dockerfile instead
RUN apk --no-cache add \
		bash \
		ca-certificates

# Principal of Least Privilege, should not run as root
USER node:node

# Copy in entrypoint
COPY --from=bundler $SCRIPTS_FOLDER $SCRIPTS_FOLDER/

# Copy in app bundle
COPY --from=bundler $APP_BUNDLE_FOLDER/bundle $APP_BUNDLE_FOLDER/bundle/

RUN bash $SCRIPTS_FOLDER/build-meteor-npm-dependencies.sh

# Start app
ENTRYPOINT ["/home/node/docker/entrypoint.sh"]

CMD ["node", "main.js"]
