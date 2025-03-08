# Ziploy Github Action

![GitHub release (latest by date)](https://img.shields.io/github/v/release/code-soup/ziploy-github-action?style=flat-square)
![License](https://img.shields.io/github/license/code-soup/ziploy-github-action?style=flat-square)

Deploy WordPress Theme or Plugin from GitHub to any hosting using [Ziploy WordPress plugin](https://www.ziploy.com) and ziploy-github-action.

---

## Overview

Ziploy is a GitHub Action that deploys a WordPress theme or plugin directly from your repository to your hosting environment via SSH with minimal configuration.
For more info please visit [ziploy.com](https://www.ziploy.com)

---

## Usage

Add the following workflow to your repository (e.g., `.github/workflows/ziploy.yml`):

```yaml
name: Deploy via Ziploy
on:
    push:
        branches:
            - master
jobs:
    deploy:
        runs-on: ubuntu-latest
        container:
            image: codesoup/beetroot:latest

    steps:
        - name: Checkout Repository
          uses: actions/checkout@v4

        - name: Deploy with Ziploy
          uses: code-soup/ziploy-github-action@latest
          with:
              ziploy-ssh-key: ${{ secrets.ZIPLOY_SSH_KEY }}
```

---

## Inputs

| Input            | Description     | Required |
| ---------------- | --------------- | -------- |
| `ziploy-ssh-key` | SSH Private Key | Yes      |

---

## Configuration

Place a `.ziployconfig` file in your repository root with the following example contents:

```dot
# .ziployconfig
# Unique identifier for deployment
id = 12345

# Remote host URL where Ziploy plugin is installed (must include http:// or https://)
origin = https://www.mywebsite.com

# Deployment method (SSH or HTTP)
method = SSH

# SSH specific options below (only needed if method is SSH)
ssh-host = ssh.mywebsite.com
ssh-user = my-ssh-username
ssh-port = 22
```

---

## Outputs

This action does not produce explicit outputs.

---

## Requirements

This GitHub Action is designed to work with the Ziploy WordPress Plugin. The Ziploy plugin must be installed and activated on your WordPress website.

---

## License

This project is licensed under the GNU General Public License Version 3. See the [LICENSE](https://github.com/code-soup/ziploy-github-action/blob/master/LICENSE.txt) file for details.

---

## Author

Maintained by [Code Soup](https://github.com/code-soup)
