# AGENTS.md

Instructions for agents working in this repository.

## Repository Overview

This is an Arch Linux dotfiles repository managed with GNU Stow. Top-level app
directories, such as `quickshell/`, `hyprland/`, `nvim/`, `kitty/`, `tmux/`,
`zsh/`, and `theming/`, are Stow packages that mirror paths under `$HOME`.

Important supporting directories:

- `.install/`: installer, package lists, and setup scripts.
- `.data/`: templates, defaults, wallpapers, themes, CLI helpers, and migrations.
- `.data/quickshell/defaults.json`: default QuickShell state used during setup.
- `quickshell/.config/quickshell/state.json`: tracked example/runtime state.
- `.data/pwcca-cli/`: `pwcca` command implementation.

## Git And Commits

- Always use Conventional Commit messages in this exact shape:
  `type(scope): message`
- Prefer concise scopes, for example:
  - `style(quickshell): polish notification cards`
  - `fix(hyprland): correct monitor setup fallback`
  - `docs(repo): add agent instructions`
  - `chore(install): update package list`
- Keep commits focused. Do not include unrelated worktree changes.
- Before committing, run `git status --short` and review the staged diff.
- Never rewrite, reset, or discard user changes unless explicitly requested.

## Editing Rules

- Preserve the existing style of the file being edited.
- Keep changes narrowly scoped to the requested behavior.
- Use ASCII unless the file already uses non-ASCII or the UI icon/font requires it.
- Use `apply_patch` for manual edits.
- Prefer `rg` for searching.
- Do not edit generated or local machine-specific files unless the request targets them.

## QuickShell Guidelines

QuickShell is QML-based and lives under `quickshell/.config/quickshell/`.

- Shared UI components live in `components/`.
- User-facing modules live in `modules/`.
- Singleton services live in `services/`.
- Global design tokens live in `config/Config.qml`.
- Runtime/default user preferences should flow through `StateService` and
  `.data/quickshell/defaults.json` when they are meant to be configurable.
- Prefer existing components such as `QsPopupWindow`, `QuickSettingsTile`,
  `QsSlider`, `ActionButton`, and `ClearButton` over introducing one-off UI.
- When changing shared components, check every call site because the visual impact
  can span calendar, system monitor, quick settings, notifications, launcher, or
  clipboard surfaces.
- Temporary notification toasts use `modules/notifications/NotificationOverlay.qml`
  and `NotificationCard.qml`; notification history uses `NotificationWindow.qml`.
- Modal panels such as calendar, system monitor, quick settings, and notification
  history share `components/QsPopupWindow.qml`.
- Keep QuickShell visual changes consistent with the fixed Tokyo Night palette in
  `Config.qml`.

## State And Defaults

- If adding, renaming, or removing a persisted setting, update
  `.data/quickshell/defaults.json` and any service code that reads it.
- Validate JSON after editing defaults:
  `node -e "JSON.parse(require('fs').readFileSync('.data/quickshell/defaults.json','utf8'))"`
- Do not assume local `~/.config/quickshell/state.json` exists or matches defaults.

## Installer And CLI

- Installer entry point: `install.sh`.
- Hyprland local setup: `.install/setup/hyprland.sh`.
- Package lists: `.install/packages/*.sh`.
- `pwcca` CLI commands: `.data/pwcca-cli/commands/*.sh`.
- Migrations: `.data/pwcca-cli/migrations/*.sh`.
- Keep setup scripts idempotent where practical. Avoid overwriting user local
  configs unless the script already has an explicit overwrite flow.

## Hyprland Guidelines

- Tracked Hyprland config is under `hyprland/`.
- Machine-local files are generated under `~/.config/hypr/local/` from templates in
  `.data/hyprland/templates/`.
- Do not hardcode monitor names, GPU assumptions, workspace layouts, or local
  paths unless the user explicitly asks.

## Verification

Use the lightest verification that matches the change:

- JSON edits: parse the JSON.
- Shell edits: run `bash -n` on changed shell scripts when possible.
- QML edits: search for stale symbol references with `rg`; if QuickShell is
  available, prefer `pwcca reload` or a direct QuickShell reload only when the user
  expects live validation.
- Git work: finish with `git status --short`.

## Communication

- Be direct and specific about files changed.
- Mention verification that was run.
- If a behavior depends on Hyprland, QuickShell, or live desktop state, say so.
