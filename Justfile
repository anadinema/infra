# Justfile containing commands for CI/CD processes.

# Rollover release for major version. Usage: just ci-roll-release 1"
[script ("bash")]
[arg('major_version', pattern='\d+')]
ci-roll-release major_version:
  set -euo pipefail

  MAJOR_VERSION=$(echo "{{ major_version }}")

  echo "🚀 Rolling update for version v${MAJOR_VERSION}"
  git tag -d "v${MAJOR_VERSION}"
  git push origin ":v${MAJOR_VERSION}"
  git tag -a "v${MAJOR_VERSION}" -m ''
  git push origin "v${MAJOR_VERSION}"

  echo "Rolling tag v${MAJOR_VERSION} updated to latest commit 🚀"
