#!/usr/bin/env bash
# One-time setup for a repo created from project-template.
#
#   gh repo create <owner>/<name> --public --template eduralph/project-template \
#     --description "<one line>" --clone
#   cd <name> && scripts/init-repo.sh
#
# GitHub copies a template's files but not its labels, settings or branch protection,
# so this script:
#   1. asks for the license (Apache-2.0 by default; PROJECT_LICENSE skips the question),
#      the contact address for conduct and policy reports (PROJECT_CONTACT) and the
#      package ecosystem for Dependabot (PROJECT_ECOSYSTEM: pip, cargo, npm, gomod or
#      none); writes LICENSE (and NOTICE for Apache-2.0 only), fills the {{...}}
#      placeholders in every tracked file from the GitHub repo + git config, drops the
#      template-only README block, its own test (.github/template-test/) and itself, then
#      commits (signed off) and pushes to main;
#   2. creates the triage labels from .github/triage/labels.json, plus `new`,
#      `release-gating`, `research` and `accessibility`;
#   3. turns off the wiki, deletes a PR's branch when it merges, and turns on private
#      vulnerability reporting, Dependabot alerts and security updates, secret scanning
#      with push protection and generic-secret patterns, code scanning (CodeQL default
#      setup), a read-only Actions token, and the immutable OIDC subject;
#   4. protects main: PRs required; the checks in REQUIRED_CHECKS required; admins
#      included; conversations resolved; no force-push or deletion;
#   5. prints what is left to do by hand to turn on automated issue triage.
#
# Steps 2-5 are idempotent; re-running after step 1 only re-applies settings.
set -euo pipefail

# The status checks main requires; each is a job in .github/workflows/.
REQUIRED_CHECKS=(dco docs-check docs-immutability gate require-linked-issue)

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
MAINTAINER="$(gh api user --jq .login)"
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

  ECOSYSTEM="${PROJECT_ECOSYSTEM:-}"
  if [ -z "$ECOSYSTEM" ] && [ -t 0 ]; then
    read -r -p "Package ecosystem for Dependabot (pip, cargo, npm, gomod, none) [none]: " ECOSYSTEM
  fi
  ECOSYSTEM="${ECOSYSTEM:-none}"
  case "$ECOSYSTEM" in
    pip|cargo|npm|gomod)
      python3 -I - "$ECOSYSTEM" <<'PY'
import sys
eco = sys.argv[1]
path = ".github/dependabot.yml"
text = open(path, encoding="utf-8").read()
entry = (f"  - package-ecosystem: {eco}\n    directory: \"/\"\n    schedule:\n"
         "      interval: weekly\n    open-pull-requests-limit: 5\n"
         "    commit-message:\n      prefix: \"deps\"\n")
anchor = "  - package-ecosystem: github-actions\n"
assert anchor in text
open(path, "w", encoding="utf-8").write(text.replace(anchor, entry + anchor, 1))
PY
      echo "Dependabot: $ECOSYSTEM and github-actions" ;;
    none) echo "Dependabot: github-actions only" ;;
    *) die "unknown PROJECT_ECOSYSTEM '$ECOSYSTEM' (pip, cargo, npm, gomod or none)" ;;
  esac

  # The template ships the Apache-2.0 text and its NOTICE; anything else replaces them.
  if [ "$CHOICE" != apache-2.0 ]; then
    gh api "licenses/$CHOICE" --jq .body \
      | sed -e "s/\[year\]/$YEAR/g" -e "s/\[fullname\]/$AUTHOR/g" > LICENSE
    git rm -q NOTICE
  fi

  # Files that only make sense in the template repository: its own test of this script.
  git rm -rq .github/template-test .github/workflows/template-test.yml

  echo "Filling placeholders for $REPO"
  python3 -I - "$NAME" "$DESCRIPTION" "$OWNER" "$YEAR" "$AUTHOR" "$LICENSE_NAME" "$DATE" \
    "$CONTACT" "$MAINTAINER" <<'PY'
import re, subprocess, sys
name, desc, owner, year, author, license_name, date, contact, maintainer = sys.argv[1:]
subs = {"{{PROJECT_NAME}}": name, "{{PROJECT_DESCRIPTION}}": desc, "{{OWNER}}": owner,
        "{{YEAR}}": year, "{{AUTHOR}}": author, "{{LICENSE_NAME}}": license_name,
        "{{DATE}}": date, "{{CONTACT_EMAIL}}": contact, "{{MAINTAINER}}": maintainer}
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

# --- 2. labels ----------------------------------------------------------------------
# The triage labels from labels.json (skipping the template's example area), then the
# labels the triage rules and the `new`-label workflow use.
python3 -I - <<'PY' | while IFS=$'\t' read -r name color desc; do
import json
config = json.load(open(".github/triage/labels.json", encoding="utf-8"))
for group in ("severity", "reach", "area", "priority", "other"):
    for name, spec in config[group].items():
        if "EXAMPLE" not in spec["description"]:
            print(f"{name}\t{spec['color']}\t{spec['description']}")
for name, color, desc in (
        ("new", "FBCA04", "Not yet assigned to a milestone (set by the Issue triage workflow)"),
        ("release-gating", "b60205", "Must be fixed before the next release (at least P1, ADR-0005)"),
        ("research", "5319e7", "Needs planning, an ADR or a proposal before anyone builds it"),
        ("accessibility", "0052cc", "A barrier for people with disabilities (at least P2, ADR-0005)")):
    print(f"{name}\t{color}\t{desc}")
PY
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null
done
echo "Labels ready"

# --- 3. repo settings ---------------------------------------------------------------
# Deleting merged branches also lets GitHub move a stacked PR onto main when its base
# merges; with the base branch left behind, the stacked PR merges into it instead.
gh repo edit "$REPO" --enable-wiki=false --delete-branch-on-merge >/dev/null
gh api -X PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null
gh api -X PUT "repos/$REPO/vulnerability-alerts" >/dev/null
gh api -X PUT "repos/$REPO/automated-security-fixes" >/dev/null
gh api -X PATCH "repos/$REPO" --input - >/dev/null <<'JSON'
{"security_and_analysis": {"secret_scanning": {"status": "enabled"},
                           "secret_scanning_push_protection": {"status": "enabled"},
                           "secret_scanning_non_provider_patterns": {"status": "enabled"}}}
JSON
# Generic patterns (private keys, connection strings, passwords) are accepted but left
# off for repos on a personal account, so report what GitHub actually did.
GENERIC="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_non_provider_patterns.status // "unavailable"')"
# Code scanning with GitHub's CodeQL default setup: it analyses the languages it finds
# (the workflows themselves at least) on pushes, pull requests and weekly. Setup runs in
# the background, so report the state GitHub returns rather than assume it took.
gh api -X PATCH "repos/$REPO/code-scanning/default-setup" -f state=configured >/dev/null 2>&1 || true
CODEQL="$(gh api "repos/$REPO/code-scanning/default-setup" --jq .state 2>/dev/null || true)"
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false >/dev/null
gh api -X PUT "repos/$REPO/actions/oidc/customization/sub" \
  -F use_default=true -F use_immutable_subject=true >/dev/null
echo "Wiki off; merged branches deleted; vulnerability reporting, Dependabot security"
echo "  updates, secret scanning on; read-only Actions token; immutable OIDC subject"
echo "  Generic-secret scanning: ${GENERIC:-unknown} (GitHub leaves it off for personal-account repos)"
echo "  Code scanning (CodeQL default setup): ${CODEQL:-unknown}"

# --- 4. branch protection -----------------------------------------------------------
CONTEXTS="$(printf '"%s",' "${REQUIRED_CHECKS[@]}")"
gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": {"strict": false, "contexts": [${CONTEXTS%,}]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "Branch protection on $BRANCH: PRs required; ${REQUIRED_CHECKS[*]} required;"
echo "  admins included"

# --- 5. what is left by hand ---------------------------------------------------------
SUBJECT="$(gh api "repos/$REPO/actions/oidc/customization/sub" --jq .sub_claim_prefix)"
cat <<EOF

Done. Left to do by hand:
  - Set up the project's checks: replace the placeholder step in
    .github/workflows/ci.yml and name the same command in CONTRIBUTING.md. Until then
    the required 'gate' check fails every pull request.
  - Fill in the documents that carry a "How to fill this in" block (start with
    docs/design/README.md), then accept ADR-0002 and ADR-0005.
  - Automated issue triage (optional): replace the example area in
    .github/triage/labels.json and fill in .github/triage/prompt.md, then in the Claude
    Console (Keys & access > Workload identity) add a federation rule for the subject
      $SUBJECT:ref:refs/heads/main
    and set its IDs as repository variables:
      gh variable set ANTHROPIC_FEDERATION_RULE_ID --repo $REPO --body <rule id>
      gh variable set ANTHROPIC_ORGANIZATION_ID    --repo $REPO --body <org id>
      gh variable set ANTHROPIC_SERVICE_ACCOUNT_ID --repo $REPO --body <service account id>
      gh variable set ANTHROPIC_WORKSPACE_ID       --repo $REPO --body <workspace id>
    Until then the Issue priority workflow skips itself.
EOF
