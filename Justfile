# Justfile containing commands for CI/CD processes.

# Rollover release for major version. Usage: just ci-roll-release 1"
[script ("bash")]
[arg('major_version', pattern='\d+')]
ci-roll-release major_version:
  set -euo pipefail

  MAJOR_VERSION="{{ major_version }}"

  echo "🚀 Rolling update for version v${MAJOR_VERSION}"
  git fetch --tags origin
  git tag -d "v${MAJOR_VERSION}" 2>/dev/null || true
  git tag -a "v${MAJOR_VERSION}" -m "🔖 retag v${MAJOR_VERSION} to latest" HEAD
  git push --force origin "refs/tags/v${MAJOR_VERSION}"

  echo "🚀 Rolling tag v${MAJOR_VERSION} updated to latest commit"
