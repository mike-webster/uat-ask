# uat-ask
A tool to help manage a UAT environment

## Dependencies
- mysql

## Preinstallation
- Create a [Slack application](https://api.slack.com/apps)
    - Follow the instructions, it's a pretty basic process
    - When on the settings page for your application, navigate to `Install App` under `Settings` on the left side - you'll need the `Bot User OAuth Access Token` for the ENV variables.
- Add Slash Commands
    - `/uat-ask`
        - Request URL
            - `{yourhost.com}/instances/ask`
    - `/uat-approve`
        - Request URL
            - `{yourhost.com}/instances/update`
    - `/uat-decline`
        - Request URL
            - `{yourhost.com}/instances/decline`
    - `/uat-help`
        - Request URL
            - `{yourhost.com}/instances/help`
    - `/uat-done`
        - Request URL
            - `{yourhost.com}/instances/done`
    - `/uat-report`
        - Request URL
            - `{yourhost.com}/instances/report`
- Configure Interactive Components
    - Request URL
        `{yourhost.com}/instances/user-response`

## Installation
- TODO

## Environment Variables
- `BOT_TOKEN`
    - The OAuth token you received while setting up the slack app
- `GATEKEEPER`
    - The Slack ID for the user who is in charge of the UAT environment (ex: U3B1QPCWJ)
- `ADMIMS`
    - This is a list of Slack IDs for users who may want read-only access to certain features.
- `SLACK_DOMAIN`
    - This is the organization's email address that are used to create user's accounts.
- `HOST`
    - The host for the database
- `DB_NAME`
    - The name for the database (optional - defaults to uatask)
- `DB_USER`
    - The username of the database user
- `DB_PASS`
    - The password for the database user