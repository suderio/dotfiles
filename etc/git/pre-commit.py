#!/usr/bin/env python3
"""Helper script to be used as a pre-commit hook."""
import sys
import subprocess


def gitleaksEnabled():
    """Determine if the pre-commit hook for gitleaks is enabled."""
    try:
        result = subprocess.run(
            ['git', 'config', '--bool', 'hooks.gitleaks'],
            capture_output=True,
            text=True,
            check=False
        )
        out = result.stdout.strip()
    except FileNotFoundError:
        out = ""

    if out == "false":
        return False
    return True


if gitleaksEnabled():
    try:
        exitCode = subprocess.run(['gitleaks', 'protect', '-v', '--staged']).returncode
    except FileNotFoundError:
        print("Warning: gitleaks is not installed or not found in PATH.")
        exitCode = 127

    if exitCode == 1:
        print('''Warning: gitleaks has detected sensitive information in your changes.
To disable the gitleaks precommit hook run the following command:

    git config hooks.gitleaks false
''')
        sys.exit(1)
else:
    print('gitleaks precommit disabled\
     (enable with `git config hooks.gitleaks true`)')
