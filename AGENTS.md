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
- Normal boot must not require `app/runtime/testing_runtime.rb`; only require it lazily when `--test` is actually active.
- Keep rendering logic in renderer classes whenever practical (`app/renderers/**`), and keep gameplay/rules in models/controllers.
- Keep board-rule logic deterministic and testable.
- Do not prefix non-test methods with `test_`; DragonRuby test discovery will treat them as tests. This applies to runtime helpers in `app/main.rb` too.
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
- Before each fresh test verification, clear any stale `errors/last.txt` so old runtime exceptions are not mistaken for the current run.
- After each test run, inspect `errors/last.txt` (runtime warning/exception signal).
- If available, also inspect `test-output.txt` (custom runner summary). If `test-output.txt` is not generated, rely on DragonRuby output summary plus `errors/last.txt`.
- When capturing DragonRuby console output via PowerShell transcript, write to `test-transcript.txt` (not `test-output.txt`) to avoid collisions with custom runner output.
- When reading captured transcript output, use a high limit (`Get-Content ... -TotalCount 10000`) so failures/warnings are not truncated.
- If a change touches runtime rendering/layout code, do not rely only on test mode; also consider a normal boot smoke check because some render-path exceptions only appear outside `--test`.

## Run Commands
- Run game from parent directory: `../dragonruby ./hallways` (Git Bash on Windows).
- Run tests from parent directory: `../dragonruby ./hallways --test app/test_runner.rb`.
- Keep `README.md` and `AGENTS.md` aligned when run/test instructions change.

## Docs Usage
- Prefer local DragonRuby docs in `docs/` as primary reference before guessing API behavior.
- Start with authored content first: `docs/api/`, `docs/guides/`, and targeted files in `docs/samples/`.
- Treat `docs/static/` and `docs/oss/` as secondary/reference-only; do not load them unless needed for a specific issue.
- Load only the smallest relevant doc files for the current task to keep context focused.
- When behavior is uncertain, cite the specific local doc path used in the change summary.

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
- Pawn visuals now render from `sprites/solid-circle.png` tinted from each pawn's RGB color.
- Player box placeholder art is still a square avatar panel with a solid-drawn `X`.
- Player palette currently exists in two places: `Game::PLAYER_COLORS` for pawns and `GameRenderer::PLAYER_BOX_PLAYER_FILLS` for UI boxes. Keep them visually aligned whenever player colors change.

## Communication
- Be direct and concise.
- If blocked, ask one precise question.
