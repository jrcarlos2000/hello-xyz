# Basecamp 12 App

This is the app we will be building together as teachers of Basecamp 12.

This repo is meant to be private to force students to code along as it's part of their homework requirement.

After clonning the repo make sure to install all frontend dependencies.

```
yarn install
```

## Dev Containers

This project is meant to be used with [Docker](https://docs.docker.com/desktop/) and the [DevContainers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension available for VSCode and Cursor.

Before opening your IDE make sure Docker is running and then, when opening the editor, you should see a pop-up to launch it inside the container defined by `.devcontainer.json`.

If you don't see the pop-up you can launch it manually by going to:

```
View -> Command Palette -> Dev Containers: Rebuild and Reopen in Container
```

## Commands

To build the project

```
yarn build
```

To run the tests

```
yarn test
```

To start the local devnet

```
yarn chain
```

To deploy the smart contract to devnet

```
yarn deploy
```

To start the frontend

```
yarn start
```