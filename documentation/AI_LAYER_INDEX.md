# AI layer index

One line each: what exists in this repo's AI layer, so people and agents can find it.
Installed from the Ticketwright plugin (project scope); rules live in `AGENTS.md`.

## Skills (prefix with `/ticketwright:` on a plugin install)
- `setup`: configure the repo, add a tool, or onboard a teammate (`/setup --teammate`).
- `ticket`: open or resume a ticket, load prior work, write the plan, wait for approval.
- `build`: execute the approved plan in small build-and-check loops, then run `review`.
- `review`: independent QC; re-runs queries and walks the validation pyramid to a verdict.
- `ship`: commit, PR, merge (asks first), back up, comment, draft chat. Hard halt before external posts.
- `refresh`: rebuild the ticket catalog (`tickets/INDEX.md`) or the domain knowledge pack.
- `skillify`: turn a recurring workflow into its own skill.

## Agent
- `qc-reviewer`: independent, read-only reviewer that returns APPROVE / REQUEST-CHANGES.

## Hooks (wired by the plugin)
- `db_write_guard`: asks before risky warehouse SQL run through a CLI.
- `source_material_guard`: asks before a raw meeting transcript is committed or backed up.
- `review_verdict_guard`: asks before pushing deliverables with no approving review on file.
- `session_context` / `ticket_index_context` / `regenerate_ticket_index`: prime and refresh the stack and ticket catalog.

## Adapters in use (see `.claude/config/stack.yaml`)
- Tracker: Jira (`adapters/tracker/jira.md`)
- Warehouse: Snowflake (`adapters/warehouse/snowflake.md`)
- Chat: Slack and Gmail (`adapters/chat/slack.md`, `adapters/chat/gmail.md`)
- Docstore: Google Drive (`adapters/docstore/gdrive.md`)
- Meetings: Notion (`adapters/meetings/notion.md`)
- Code host: GitHub (`adapters/vcs/github.md`)
