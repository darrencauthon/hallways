# Hallways

Hallways is a DragonRuby implementation of the Quoridor board game.

Current status:
- Title screen with keyboard menu.
- `Start` opens a blank game screen placeholder.
- `Quit` exits the app.
- Test runner support through DragonRuby CLI test mode.
- Core model extraction in progress:
  - `Game` owns `board`, `pawns`, and reserve `walls`.
  - `Board` owns 9x9 `Square` objects.
  - `Pawn` and `Wall` are render-capable objects.

## Requirements

- DragonRuby Game Toolkit (Pro is fine).
- This repo in a folder next to your `dragonruby` executable.

## Run The Game

From the parent directory (example: `dragonruby-mine`):

```bash
./dragonruby ./hallways
```

On Windows Git Bash, this is commonly:

```bash
../dragonruby ./hallways
```

Controls on title screen:
- `Up` / `Down`: change selected option.
- `Enter`: confirm selection.

## Run Tests

DragonRuby test mode requires a test-path argument.

From the parent directory:

```bash
./dragonruby ./hallways --test app/test_runner.rb
```

On Windows Git Bash:

```bash
../dragonruby ./hallways --test app/test_runner.rb
```

Expected behavior:
- Test output is printed to console.
- DragonRuby exits automatically after tests complete.
- Warnings in test output should be treated as failures to investigate, even if process exit is successful.
- Custom test summary is written to `test-output.txt` for automation checks.
- Current suite includes title screen, pawn, and game-initial-state tests.

## Notes

- Do not use standard Ruby CLI (`ruby`) for validation in this project.
- Hallways uses DragonRuby runtime behavior as the source of truth.
- Avoid naming non-test methods with a `test_` prefix; DragonRuby test discovery treats them as tests.
- For automated review, check both `test-output.txt` and `errors/last.txt` after test runs.
- Naming convention used in this project:
  - `Board` means the 9x9 play grid.
  - `Wall` means reserve/placeable wall pieces (not the board itself).
