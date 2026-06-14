# LiveKit Voice Agent iOS PoC

## Overview

This project is a Proof of Concept (PoC) demonstrating the integration of an iOS application with a LiveKit Cloud Voice Agent.

The goal is to provide a hands-free conversational experience where users can interact with an AI-powered voice assistant through LiveKit's real-time audio infrastructure.

The project focuses on:

- LiveKit Cloud integration
- Voice Agent interaction
- Real-time audio communication
- Siri / App Intents exploration
- iOS native implementation using Swift

---

## Prerequisites

Before running the project, make sure you have:

- Xcode 16+
- iOS 18+ Simulator or physical device
- A LiveKit Cloud account
- A deployed LiveKit Agent
- Git installed

---

## Clone the Repository

```bash
git clone https://github.com/Dsanabriabr/ios_voice_livekit-poc
cd ios_voice_livekit-poc
```

---

## Install Dependencies

This project uses Swift Package Manager (SPM).

When opening the project in Xcode, package dependencies should be resolved automatically.

If necessary, manually resolve packages using:

```bash
xcodebuild -resolvePackageDependencies
```

or inside Xcode:

```text
File → Packages → Resolve Package Versions
```

Wait until all packages are downloaded successfully before building the project.

---

## LiveKit Cloud Setup

Before running the application, you must configure a LiveKit Cloud project.

### Step 1 – Create an API Key

Open your LiveKit Cloud dashboard.

Navigate to:

```text
Settings
 └── Project
      └── API Keys
```

Create a new API Key.

---

### Step 2 – Generate an Access Token

After creating the API Key:

1. Click the three-dot menu next to the key.
2. Select **Generate Token**.
3. Generate a token for a room.

Important:

- Save the generated token.
- Save the room name used during token creation.

You will need both values when running the application.

---

## Create and Deploy a Voice Agent

Before running the iOS application, a LiveKit Agent must be created and deployed.

The agent setup follows the official LiveKit documentation:

https://docs.livekit.io/agents/start/voice-ai/#livekit-cloud

Follow the guide to:

1. Install the LiveKit CLI.
2. Create a new Voice Agent.
3. Deploy the agent to LiveKit Cloud.

---

## Start the Agent

After deploying the agent, dispatch it to the room created previously.

Example:

```bash
lk dispatch create \
  --agent-name my-agent \
  --room test
```

Replace:

- `my-agent` with the name of your deployed agent.
- `test` with the room name used when generating the access token.

Once the dispatch command succeeds, the agent will join the room and be ready to receive connections from the iOS application.

---

## Run the iOS Application

Open the project in Xcode.

Build and run the application on:

- A physical iPhone (recommended)
- An iOS Simulator

The application should connect to the configured LiveKit room and establish a conversation with the deployed Voice Agent.

---

## Technical Notes

### Apple Watch Investigation

During development, an Apple Watch version was investigated.

However, the current LiveKit SDK depends on WebRTC and Rust UniFFI binaries that are not distributed for watchOS.

As a result:

- iOS is supported
- macOS is supported
- visionOS is supported
- tvOS is supported
- watchOS is currently not supported by the SDK binaries

For this reason, the PoC focuses on the iPhone experience.

---

## Architecture Summary

```text
User
  ↓
iOS App
  ↓
LiveKit Room
  ↓
LiveKit Cloud Agent
  ↓
LLM
  ↓
Function Calling (optional)
  ↓
Backend Services
```

---

## Demo

Two demonstration videos are provided separately:

1. End-user interaction flow.
2. Technical walkthrough of the implementation and LiveKit integration.

---

## Author

Daniel Sanabria - iOS Engineer