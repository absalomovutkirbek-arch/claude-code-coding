---
name: setup-stack
description: Install the Claude Code setup for this project's stack (Yii2, Laravel, Spring Boot or React) from the claude-code-coding repository, then adopt the project. Use when the developer asks to install, add, set up or update the coding setup, standard or rules in a project.
argument-hint: "[yii2 | laravel | spring-boot | react] [path, default: current project]"
---

# Set up a stack in this project

Request: `$ARGUMENTS`

## 1. Find the setup repository

Use the first one that exists:

1. `__SETUP_REPO__` (written by `install.sh --global`);
2. a `claude-code-coding` folder next to the project folder (`../claude-code-coding`);
3. otherwise clone it: `git clone --depth 1 https://github.com/absalomovutkirbek-arch/claude-code-coding.git ~/.claude/setups/claude-code-coding`.

If it is a git clone, update it with `git -C <repo> pull --ff-only`. If the pull fails, continue with the local copy and say so.

## 2. Decide the stack

Use the stack from the request if given. Otherwise detect it in the target folder:

| Found | Stack |
| --- | --- |
| `composer.json` requires `laravel/framework` | `laravel` |
| `composer.json` requires `yiisoft/yii2` | `yii2` |
| `pom.xml` or `build.gradle(.kts)` uses `spring-boot` | `spring-boot` |
| `package.json` depends on `react` | `react` |

- Nothing found (a new, empty project): ask the developer which stack, and create the project skeleton only if they ask for it.
- More than one found (for example `backend/` and `frontend/` in one repository): install each stack into its own folder and tell the developer to start Claude Code inside that folder when working on it.

## 3. Install

1. Run `git status --short` in the target. If there are uncommitted changes, list them and continue: the installer only touches `CLAUDE.md` and `.claude/`.
2. Run `bash <repo>/install.sh <stack> <target>`.
3. If the installer wrote `CLAUDE.md.new` or `.claude/settings.json.new`, the project already had its own file:
   - `CLAUDE.md`: take the new file as the base, move the project's own instructions into "Project facts" and "Project-specific overrides", show the developer the result, then replace the old file and delete the `.new` file.
   - `settings.json`: merge `permissions` and `hooks` from the new file into the existing one without dropping the project's own entries, then delete the `.new` file.

## 4. Adopt the project

Run the `/adopt-project` procedure: if the skill is not listed yet, read `<target>/.claude/skills/adopt-project/SKILL.md` and follow it. It fills "Project facts" in `CLAUDE.md` and reports where the project differs from the standard.

## 5. Report

- Stack, target folder and the setup repository revision (`git -C <repo> log -1 --format=%h`).
- Files installed or merged, and what `/adopt-project` found.
- Next steps: commit `CLAUDE.md` and `.claude/`; run `/foundation` once if the shared kernel is missing; start a new Claude Code session if the new slash commands do not appear.

Do not commit or push unless the developer asks.
