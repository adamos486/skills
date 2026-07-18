# Implementation Plan: Stale Branch Reminder

## Goal

Branches on our main repo sit unmerged for months and nobody notices. Post a weekly Slack
message listing branches with no commits in 30+ days, and who owns them.

Stack: Python 3.12, single script run by an existing GitHub Actions cron. No new services.

## Constraints

- Must use the existing `SLACK_WEBHOOK_URL` repo secret. No new credentials.
- Read-only against the repo. It must never push, delete, or modify a branch.

## Work

1. Script `stale_branches.py`: call the GitHub API for branches, filter to those whose last
   commit is older than 30 days, resolve each branch's last committer.
2. Format a Slack message: branch name, owner, days stale. Skip the post entirely when the
   list is empty.
3. Add a workflow file running it Mondays at 9am, plus `workflow_dispatch` for manual runs.

## Acceptance

- Running with `--dry-run` against the real repo prints the message without posting.
- A manual `workflow_dispatch` run posts to the team channel.
