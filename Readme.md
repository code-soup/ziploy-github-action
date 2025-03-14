# Ziploy Github Action

![GitHub release (latest by date)](https://img.shields.io/github/v/release/code-soup/ziploy-github-action?style=flat-square)
![License](https://img.shields.io/github/license/code-soup/ziploy-github-action?style=flat-square)

Deploy WordPress Theme or Plugin from GitHub to any hosting using the [Ziploy WordPress plugin](https://www.ziploy.com) and the ziploy-github-action.

---

## Overview

Ziploy is a GitHub Action that deploys a WordPress theme or plugin directly from your repository to your hosting environment via SSH with minimal configuration. For more information, please visit [ziploy.com](https://www.ziploy.com).

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
              uses: code-soup/ziploy-github-action@0.0.1
              with:
                  ziploy-ssh-key: ${{ secrets.ZIPLOY_SSH_KEY }}
                  ziploy-working-directory: ${{ inputs.ziploy-working-directory }}
```

---

## Inputs

| Input                      | Description                                                         | Required |
| -------------------------- | ------------------------------------------------------------------- | -------- |
| `ziploy-ssh-key`           | SSH Private Key                                                     | Yes      |
| `ziploy-working-directory` | Path to the working directory if different from the repository root | No       |

---

# Ziploy Working Directory

The **ziploy-working-directory** parameter is a custom input for the Ziploy GitHub Action that specifies where to locate the `.ziployconfig` file and where to download and run the Ziploy CLI binary. This parameter is requuired when your repository organizes files in subdirectories rather than at the repository root. By providing a relative path, the action can correctly reference its configuration and operate within the intended directory.

## How It Works

By default, GitHub Actions runs in the repository root. However, the Ziploy GitHub Action accepts a working directory input (typically named `working-directory`) that tells the action to:

-   Look for the `.ziployconfig` file in a specified subdirectory.
-   Download and execute the Ziploy CLI binary inside that subdirectory.

This is required if your WordPress theme or plugin is not located at the root of your repository, and your deployment configuration resides in a folder like `wp-content/themes/my-theme`.

## Configuration

Place a `.ziployconfig` file in your repository root (or in your specified working directory) with the following example contents:

```dot
# .ziployconfig
# Unique identifier for deployment
id = 12345

# Remote host URL where the Ziploy plugin is installed (must include http:// or https://)
origin = https://www.mywebsite.com

# Deployment method (SSH or HTTP)
method = SSH

# SSH specific options below (only needed if method is SSH)
ssh-host = ssh.mywebsite.com
ssh-user = my-ssh-username
ssh-port = 22

# Enable verbose logging (true or false)
verbose = false
```

After the SSH key has been saved and the known_hosts file generated, the action will update the configuration file with the file paths for the SSH key and known_hosts file.
This ensures action loads correct SSH key and known_hosts when executing SSH commands.

---

## Outputs

This action does not produce explicit outputs.

---

## Requirements

This GitHub Action is designed to work exclusively with the Ziploy WordPress Plugin. The Ziploy plugin must be installed and activated on your WordPress website.

---

## License

This project is licensed under the GNU General Public License Version 3. See the [LICENSE](https://github.com/code-soup/ziploy-github-action/blob/master/LICENSE.txt) file for details.

---

## Author

Maintained by [Code Soup](https://github.com/code-soup)
