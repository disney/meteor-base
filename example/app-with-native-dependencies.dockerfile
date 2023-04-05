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
FROM node:14.21.3-alpine AS builder

ENV NODE_HOME /home/node
ENV APP_BUNDLE_FOLDER $NODE_HOME/bundle
ENV SCRIPTS_FOLDER $NODE_HOME/docker

# Install OS build dependencies, which stay with this intermediate image but don’t become part of the final published image
RUN apk --no-cache add \
	bash \
	g++ \
	make \
	python3

# Principal of Least Privilege, should not run as root
USER node:node

# Copy in entrypoint
COPY --from=bundler $SCRIPTS_FOLDER $SCRIPTS_FOLDER/

# Copy in app bundle
COPY --from=bundler $APP_BUNDLE_FOLDER/bundle $APP_BUNDLE_FOLDER/bundle/

RUN bash $SCRIPTS_FOLDER/build-meteor-npm-dependencies.sh --build-from-source


# Start another Docker stage, so that the final image doesn’t contain the layer with the build dependencies
# See previous FROM line; this must match
FROM node:14.21.3-alpine

ENV NODE_HOME /home/node
ENV APP_BUNDLE_FOLDER $NODE_HOME/bundle
ENV SCRIPTS_FOLDER $NODE_HOME/docker

# Install OS runtime dependencies
RUN apk --no-cache add \
	bash \
	ca-certificates

# Copy in entrypoint with the built and installed dependencies from the previous image
COPY --from=builder $SCRIPTS_FOLDER $SCRIPTS_FOLDER/

# Copy in app bundle with the built and installed dependencies from the previous image
COPY --from=builder $APP_BUNDLE_FOLDER/bundle $APP_BUNDLE_FOLDER/bundle/

# Start app
ENTRYPOINT ["/home/node/docker/entrypoint.sh"]

CMD ["node", "main.js"]
