# WebCord Homebrew Tap

[![Update WebCord Cask](https://github.com/Rakeen70210/homebrew-webcord/actions/workflows/update-cask.yml/badge.svg)](https://github.com/Rakeen70210/homebrew-webcord/actions/workflows/update-cask.yml)

This is a personal [Homebrew tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap) that provides a Cask for installing the [WebCord](https://github.com/SpacingBat3/WebCord) application on macOS.

## Why This Tap Exists

WebCord is an excellent open-source application, but it is not currently "signed" or "notarized" through the Apple Developer Program. On modern versions of macOS, this causes the Gatekeeper security feature to block the app from running, showing a misleading error message like **“WebCord” is damaged and can’t be opened.**

This Cask solves the problem automatically. It includes a `postflight` command that runs after installation to remove the quarantine attribute from the application. This allows WebCord to run without any manual workarounds.

This tap provides a simple, reliable, and fully automated way to install and maintain WebCord.

## Installation

Installing WebCord using this tap is a simple, two-step process.

1.  **Tap the Repository**

    Add this tap to your local Homebrew setup. You only need to do this once.

    ```bash
    brew tap Rakeen70210/homebrew-webcord
    ```

2.  **Install the Cask**

    Now you can install WebCord just like any official Homebrew Cask.

    ```bash
    brew install --cask webcord
    ```

That's it! WebCord will be installed in your `/Applications` folder and ready to use.

## Automatic Updates

This repository is configured with a **GitHub Actions workflow** that automatically keeps the WebCord Cask up to date.

*   **Daily Check:** Once a day, an automated process runs the `generate_webcord_cask.sh` script.
*   **Update Detection:** The script checks WebCord's GitHub releases for any new versions.
*   **Automatic Commit:** If a new version is found, the script regenerates the `webcord.rb` Cask file with the new version number and checksums, then commits and pushes the update directly to this repository.

To get the latest version of WebCord, all you need to do is run the standard Homebrew command:

```bash
brew upgrade