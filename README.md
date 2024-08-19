# Base Docker Image for Meteor Apps

This repo contains a base Docker image for use by [Meteor](https://www.meteor.com/) apps built using a [multistage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/). You might want to use this base because:

- You can build/bundle your Meteor app as part of building your Docker image, rather than outside of Docker before the Docker build. This means the machine doing the building need not have Node or Meteor installed, which is important for continuous integration setups; and ensures repeatable builds, since the build environment is isolated and controlled.

- Using a multistage `Dockerfile` on your app’s side means that you can publish a much smaller final Docker image that doesn’t have Meteor included, and you can also use an Alpine Linux base which is good for passing security scans (as it presents much less surface area in which scanners might find vulnerabilities).

## Quickstart

### Step 1: Bootstrap `Dockerfile` from template

Copy `example/default.dockerfile` (or `example/app-with-native-dependencies.dockerfile` if your app has native dependencies that require compilation such as `bcrypt`, or if your app is using a version of Meteor older than 1.8.1) into the root of your project and rename it `Dockerfile`. This file assumes that your Meteor app is one level down from the root in a folder named `app`; either move your app there, or edit `Dockerfile` to point to your desired path (or the root of your project). Leave `Dockerfile` at the root.

### Step 2: Set the correct Meteor version in the `Dockerfile`

Edit the `Dockerfile` you copied into your project, changing the first line so that the numbers at the end match the version of Meteor of your project. You can find your project’s Meteor version in your app’s `.meteor/release` file.

For example, if your project is running under Meteor 3.0.2:

```Dockerfile
FROM geoffreybooth/meteor-base:3.0.2
```

This version must match an available tag from [geoffreybooth/meteor-base](https://hub.docker.com/r/geoffreybooth/meteor-base/tags).

If necessary, update version in the `FROM node` line to use the Node version appropriate for your release of Meteor. From your application folder, you can get this version via the following command:

```bash
docker run --rm geoffreybooth/meteor-base:$(cat ./.meteor/release | cut -c8-99) meteor node --version | cut -c2-99 | grep -o "[0-9\.]*"
```

### Step 3: Configure `.dockerignore` to speed up builds

Copy `example/.dockerignore` to your project’s root and edit it appropriately to avoid copying unnecessary files into the Docker context.

### Step 4: Build and run

Copy `example/docker-compose.yml` to your project’s root. Then, from the root of your project, run:

```bash
docker-compose up
```

This builds an image for your app and starts it, along with a linked container for MongoDB. Go to [http://localhost/](http://localhost/) to see your app running.

### Going further

Feel free to edit the `Dockerfile` you copied into your project, for example to add Linux dependencies. The beauty of the multistage build pattern is that this base image can stay lean, without needing `ONBUILD` triggers or configuration files for you to influence the image that gets built. You control the final image via your own `Dockerfile`, so you can do whatever you want.

If you want any command run on startup before the Meteor app itself is run, have your Dockerfile save a file `startup.sh` into `$SCRIPTS_FOLDER`. It will be executed automatically by `entrypoint.sh`.

## Why this image, instead of some others?

There are several great Meteor Docker images out there. We built this one because none of the existing open source ones met our needs:

- [jshimko/meteor-launchpad](https://github.com/jshimko/meteor-launchpad) is great, but it’s based on `debian:jessie`, which fails the security scan we run on all of our Docker images. Debian is also larger than Alpine. This project also always downloads and installs Meteor on every production build, rather than caching it as this base image does.

- [meteor/galaxy-images](https://github.com/meteor/galaxy-images) and [Treecom/meteor-alpine](https://github.com/Treecom/alpine-meteor) both require building the Meteor app in the host machine, before copying the built app into the Docker container. We wanted to avoid needing Node and Meteor installed on our CI servers, and we want the predictability of building within the Docker environment.

Other projects I looked at generally had one or more of the disadvantages cited above. Multistage Docker builds have only been possible since Docker 17.05, which came out in May 2017, and most projects on the Web were designed before then and therefore don’t take advantage of the possibilities offered by a multistage architecture.

## Contributing

### Adding a new Meteor version

Each new Meteor release requires new base images to be built and published. There’s a script in this repo to automate supporting a new Meteor version. For an example Meteor version 7.7.7 that requires Node 8.8.8, run:

```bash
# Install Meteor if you haven’t already; see https://www.meteor.com/developers/install

# Install npm-check-updates if you haven’t already
npm install --global npm-check-updates

./update.sh --meteor-version 7.7.7 --node-version 8.8.8
```

This will update the various files in this repo that need changing for each new Meteor release. Commit this change on a new branch and open a pull request to this repo to get the new version added. Once the PR is merged, `./build.sh && ./test.sh && ./push.sh` will be run to rebuild, test and publish all images for all versions of Meteor ≥ 1.9. This will also update the version of Ubuntu in the base images to the latest Ubuntu version.

### Test

```bash
# Build all images
./build.sh

# Test all images (requires Node, uses Puppeteer which will download headless Chrome)
./test.sh
```
