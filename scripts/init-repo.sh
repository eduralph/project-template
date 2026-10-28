#!/usr/bin/env bash
# One-time setup for a repo created from project-template.
#
#   gh repo create <owner>/<name> --public --template eduralph/project-template \
#     --description "<one line>" --clone
#   cd <name> && scripts/init-repo.sh
#
# GitHub copies a template's files but not its labels, settings or branch protection,
# so this script:
#   1. asks for the license (Apache-2.0 by default; set PROJECT_LICENSE to skip the
#      question) and the contact address for conduct and policy reports (PROJECT_CONTACT),
#      writes LICENSE (and NOTICE for Apache-2.0 only), fills the {{...}}
#      placeholders in every tracked file from the GitHub repo + git config, drops the
#      template-only README block and itself, then commits (signed off) and pushes to main;
#   2. creates the `needs-issue` label the PR triage workflow uses;
#   3. turns on private vulnerability reporting and turns off the wiki;
#   4. protects main: PRs required, `dco` and `docs-immutability` required, admins
#      included, conversations
#      resolved, no force-push or deletion.
#
# Steps 2-4 are idempotent; re-running after step 1 only re-applies settings.
set -euo pipefail

die() { echo "init-repo: $*" >&2; exit 1; }

command -v gh >/dev/null || die "gh is not installed"
command -v python3 >/dev/null || die "python3 is not installed"
gh auth status >/dev/null 2>&1 || die "run 'gh auth login' first"
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git checkout"

read -r REPO IS_TEMPLATE BRANCH < <(gh repo view --json nameWithOwner,isTemplate,defaultBranchRef \
  --jq '[.nameWithOwner, .isTemplate, .defaultBranchRef.name] | @tsv')
[ "$IS_TEMPLATE" = "true" ] && die "$REPO is the template itself; run this in a repo created from it"
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"
DESCRIPTION="$(gh repo view --json description --jq .description)"
AUTHOR="$(git config user.name || true)"
[ -n "$AUTHOR" ] || AUTHOR="$(gh api user --jq '.name // .login')"
YEAR="$(date +%Y)"
DATE="$(date '+%d.%m.%Y %H:%M')"

# --- 1. license + placeholders -----------------------------------------------------
if grep -q '{{PROJECT_NAME}}' README.md 2>/dev/null; then
  [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"
  [ -n "$DESCRIPTION" ] || die "set a repo description first: gh repo edit --description '...'"

  LICENSES=(apache-2.0 mit gpl-3.0 agpl-3.0 mpl-2.0)
  CHOICE="${PROJECT_LICENSE:-}"
  if [ -z "$CHOICE" ]; then
    if [ -t 0 ]; then
      echo "License:"
      echo "  1) Apache-2.0 (default)"
      echo "  2) MIT"
      echo "  3) GPL-3.0-or-later"
      echo "  4) AGPL-3.0-or-later"
      echo "  5) MPL-2.0"
      read -r -p "Choose [1]: " n
      n="${n:-1}"
      [[ "$n" =~ ^[1-5]$ ]] || die "no such choice: $n"
      CHOICE="${LICENSES[$((n - 1))]}"
    else
      CHOICE=apache-2.0
    fi
  fi
  case "$CHOICE" in
    apache-2.0) LICENSE_NAME="Apache License, Version 2.0" ;;
    mit)        LICENSE_NAME="MIT License" ;;
    gpl-3.0)    LICENSE_NAME="GNU General Public License v3.0 or later" ;;
    agpl-3.0)   LICENSE_NAME="GNU Affero General Public License v3.0 or later" ;;
    mpl-2.0)    LICENSE_NAME="Mozilla Public License 2.0" ;;
    *) die "unknown PROJECT_LICENSE '$CHOICE' (use one of: ${LICENSES[*]})" ;;
  esac
  echo "Using the $LICENSE_NAME"

  # Published in the Code of Conduct and GOVERNANCE.md, so it must be a mailbox someone
  # reads and that may be public. No default: a personal address shouldn't land there
  # by accident.
  CONTACT="${PROJECT_CONTACT:-}"
  if [ -z "$CONTACT" ] && [ -t 0 ]; then
    read -r -p "Contact email for conduct and policy reports (published): " CONTACT
  fi
  [[ "$CONTACT" == *@*.* ]] || die "set a contact email (PROJECT_CONTACT=policy@example.org)"

  # The template ships the Apache-2.0 text and its NOTICE; anything else replaces them.
  if [ "$CHOICE" != apache-2.0 ]; then
    gh api "licenses/$CHOICE" --jq .body \
      | sed -e "s/\[year\]/$YEAR/g" -e "s/\[fullname\]/$AUTHOR/g" > LICENSE
    git rm -q NOTICE
  fi

  echo "Filling placeholders for $REPO"
  python3 -I - "$NAME" "$DESCRIPTION" "$OWNER" "$YEAR" "$AUTHOR" "$LICENSE_NAME" "$DATE" \
    "$CONTACT" <<'PY'
import re, subprocess, sys
name, desc, owner, year, author, license_name, date, contact = sys.argv[1:]
subs = {"{{PROJECT_NAME}}": name, "{{PROJECT_DESCRIPTION}}": desc, "{{OWNER}}": owner,
        "{{YEAR}}": year, "{{AUTHOR}}": author, "{{LICENSE_NAME}}": license_name,
        "{{DATE}}": date, "{{CONTACT_EMAIL}}": contact}
tracked = subprocess.run(["git", "ls-files", "-z"], capture_output=True, text=True,
                         check=True).stdout.split("\0")
changed = []
for path in filter(None, tracked):
    if path == "scripts/init-repo.sh":
        continue
    try:
        text = open(path, encoding="utf-8").read()
    except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
        continue
    new = re.sub(r"\n<!-- template:begin -->.*?<!-- template:end -->\n\n", "\n", text, flags=re.S)
    for key, value in subs.items():
        new = new.replace(key, value)
    if new != text:
        open(path, "w", encoding="utf-8").write(new)
        changed.append(path)
left = [p for p in changed if re.search(r"\{\{[A-Z_]+\}\}", open(p, encoding="utf-8").read())]
if left:
    sys.exit(f"init-repo: unknown placeholders left in {left}")
print(f"  filled {len(changed)} files")
PY
  git rm -q scripts/init-repo.sh
  git add -A
  git commit -q -s -m "chore: initialize from project-template" \
    -m "Choose the license, fill the project placeholders and drop the template-only setup script."
  git push -q origin "HEAD:$BRANCH"
else
  echo "Placeholders already filled; re-applying GitHub settings only"
fi

# --- 2. label -----------------------------------------------------------------------
gh label create needs-issue --repo "$REPO" --color d93f0b \
  --description "Code change without a linked issue" --force >/dev/null
echo "Label 'needs-issue' ready"

# --- 3. repo settings ---------------------------------------------------------------
gh repo edit "$REPO" --enable-wiki=false >/dev/null
gh api -X PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null
echo "Private vulnerability reporting on, wiki off"

# --- 4. branch protection -----------------------------------------------------------
gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" --input - >/dev/null <<'JSON'
{
  "required_status_checks": {"strict": false, "contexts": ["dco", "docs-immutability"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "Branch protection on $BRANCH: PRs required, dco and docs-immutability required, admins included"
echo "Done."
