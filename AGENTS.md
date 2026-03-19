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
- Prefer `attr_reader` access for object state over strict getter encapsulation in gameplay classes.
- Use method-level encapsulation (`private` methods) when helpful, but do not over-hide plain state.

## DragonRuby Conventions
- Entry point: `app/main.rb`.
- Runtime split:
  - `app/runtime/testing_runtime.rb` handles `--test` mode.
  - `app/runtime/playing_runtime.rb` handles normal game/screen flow.
  - `app/runtime/shared_runtime.rb` contains shared runtime helpers.
- Keep rendering logic in renderer classes whenever practical (`app/renderers/**`), and keep gameplay/rules in models/controllers.
- Keep board-rule logic deterministic and testable.
- Do not prefix non-test methods with `test_`; DragonRuby test discovery will treat them as tests.
- Naming rule: `Board` is the 9x9 grid; `Wall` is a reserve/placeable wall piece.
- Be conservative with keyword-argument-heavy interfaces across renderer boundaries; DragonRuby Ruby subset can behave differently than MRI in some call paths.

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
- After each test run, inspect `errors/last.txt` (runtime warning/exception signal).
- If available, also inspect `test-output.txt` (custom runner summary). If `test-output.txt` is not generated, rely on DragonRuby output summary plus `errors/last.txt`.
- When capturing DragonRuby console output via PowerShell transcript, write to `test-transcript.txt` (not `test-output.txt`) to avoid collisions with custom runner output.
- When reading captured transcript output, use a high limit (`Get-Content ... -TotalCount 10000`) so failures/warnings are not truncated.

## Run Commands
- Run game from parent directory: `../dragonruby ./hallways` (Git Bash on Windows).
- Run tests from parent directory: `../dragonruby ./hallways --test app/test_runner.rb`.
- Keep `README.md` and `AGENTS.md` aligned when run/test instructions change.

## Architecture Snapshot
- Folder layout:
  - `app/models`: gameplay/state objects (`Game`, `Board`, `Pawn`, `Player`, `Wall`, `WallWell`, `Square`)
  - `app/controllers`: human/bot move logic
  - `app/renderers`: all rendering orchestration and draw details
  - `app/screens`: screen-level input + flow (`title`, `setup`, `game`, `victory`)
  - `app/tests`: test files
  - `app/runtime`: test/play runtime entry orchestration
- `Game` owns core match state and rules.
- `GameRenderer` owns board/pawn/wall composition rendering.
- `GameScreenRenderer` owns screen-level visual helpers (for example: thinking indicator and background).
- Pawn art currently uses sprite sheets (`source_x/source_y/source_w/source_h`) and frame dimensions must match the actual asset frame size.

## Communication
- Be direct and concise.
- If blocked, ask one precise question.
