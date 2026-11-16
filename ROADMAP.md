# Roadmap

Hours are estimates, about 82 in all.

## Finish the rebuild (about 40 hours)

| Item | Hours |
|---|---|
| Record screen on top of `Recorder`: hold to record, the progress ring, flip, torch, zoom and deleting the last clip, with a checklist for testing the camera on an iPhone | 4 |
| Go service: the v2 JSON API contract, error codes, config, the server and middleware, and MongoDB in Docker behind `make up` | 6 |
| Sessions, users and follows, with a dev sign in until Sign in with Apple | 3 |
| Uploads: upload URLs, a local disk store for videos and thumbnails, size and quota limits | 3 |
| Posts, likes and the feed, and a janitor for uploads that never became a post | 3 |
| Seed data with made up people and videos, and a benchmark for the feed query | 1 |
| API client in the app, tested against the contract | 3 |
| Sign in, feed and profile screens | 5 |
| Draft state for a video between Record, Edit and Post | 2 |
| Edit and Post screens: trim, text, export and upload, with a walk through on the simulator | 6 |
| A curl walk through of the API, a README for the package, and a GitHub issue for each row of this file | 4 |

## After that (about 42 hours)

| Item | Hours |
|---|---|
| Publish WindmillVideo so other apps can add it by URL: a root `Package.swift`, version tags, documented API and a small example app | 3 |
| Sign in with Apple in place of the dev sign in, with the Apple token checked in Go and a username step on first sign in | 5 |
| Comments | 3 |
| Activity feed for follows, likes and comments | 2 |
| Search for people | 2 |
| Background upload with retry, and drafts | 3 |
| Speed ramps and color filters in the editor | 4 |
| Smooth loop option: blend the last moment into the first on export, so the restart does not jump | 2 |
| Text timing: set when each text appears and goes | 1 |
| Feed: pull to refresh and double tap to like | 1 |
| Profile editing: the username and display picture | 2 |
| Save the edited video to Photos on Post, as in 2020 | 1 |
| Push notifications for likes and follows | 3 |
| Feed cache size limits and better preloading | 2 |
| Block and report | 2 |
| Accessibility: VoiceOver and Dynamic Type | 2 |
| A self hosted demo with made up data: a container host, MongoDB Atlas and S3 with presigned uploads | 4 |
