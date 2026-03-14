# Hallways Agent Guide

## Project
- Game: Hallways (Quoridor implementation) in DragonRuby.
- Platform target: desktop first, publish on itch.io.

## Collaboration Style
- Work step-by-step; do not jump ahead.
- Prefer execution mode and plan in very small increments while implementing.
- Propose small increments and wait for next instruction.
- Explain changes briefly and clearly.
- Keep this `AGENTS.md` up to date as new workflow/runtime constraints are discovered.

## Git Workflow
- Do not create commits unless explicitly asked.
- User handles commit timing and commit messages.

## Code Preferences
- Keep code simple and readable.
- Prefer small methods and clear naming.
- Avoid dependencies unless approved first.

## DragonRuby Conventions
- Entry point: `app/main.rb`.
- As code grows, separate rendering and game logic.
- Keep board-rule logic deterministic and testable.
- Do not prefix non-test methods with `test_`; DragonRuby test discovery will treat them as tests.

## Verification
- After each code change, state exactly how to run and what to check.
- Call out known limitations and TODOs.
- Use DragonRuby test mode with a test-path argument (example: `../dragonruby hallways --test app/test_runner.rb`).
- For AI-driven execution, prefer `--test` runs with a test path; launching without `--test` starts the interactive game loop and may not exit on its own.
- Do not use `ruby` CLI checks (for example `ruby -c`) for validation; DragonRuby uses a Ruby subset and runtime behavior can differ.
- Treat `../dragonruby hallways --test app/test_runner.rb` as the source of truth for automated verification.
- Treat warnings in DragonRuby test output as actionable problems and fix them before considering test runs clean.
- Agent must run tests directly before moving on; do not rely on user-run tests as the only signal.
- A test run is not considered clean unless there are zero warnings and zero failures.
- After each test run, inspect `test-output.txt` (custom runner summary) and `errors/last.txt` (runtime warning/exception signal).

## Run Commands
- Run game from parent directory: `../dragonruby ./hallways` (Git Bash on Windows).
- Run tests from parent directory: `../dragonruby ./hallways --test app/test_runner.rb`.
- Keep `README.md` and `AGENTS.md` aligned when run/test instructions change.

## Communication
- Be direct and concise.
- If blocked, ask one precise question.
