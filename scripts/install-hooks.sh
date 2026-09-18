#!/usr/bin/env bash
# Wire the versioned hooks of .githooks into this clone, here and in every
# submodule that carries its own.
#
# Run once per clone. core.hooksPath is a repository setting, so a fresh clone
# starts with none and every hook in .githooks is dead until this runs. Nothing
# warns about it, which is why the lines below print what git actually resolved
# rather than claiming success.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Full path on purpose: the workstation profile aliases chmod, and the alias
# chokes on these arguments.
git config --local core.hooksPath .githooks
/bin/chmod +x .githooks/* scripts/*.sh
echo "$(basename "$REPO_ROOT"): core.hooksPath = $(git config --get core.hooksPath), pre-push runs scripts/history-scan.sh then scripts/security-scan.sh"

# A submodule that is not checked out, or whose installer lost its executable
# bit, says so out loud. Skipping in silence would let someone read the success
# line above and believe all three stations are wired when none of them is.
for module in */; do
	module="${module%/}"
	[ -e "$module/.git" ] || continue
	installer="$module/scripts/install-hooks.sh"
	if [ -x "$installer" ]; then
		"$installer"
	elif [ -f "$installer" ]; then
		echo "$module: NOT wired, $installer is not executable"
	else
		echo "$module: no gate of its own, nothing to wire"
	fi
done
