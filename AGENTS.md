# Hallways Agent Guide

## Project
- Game: Hallways (Quoridor implementation) in DragonRuby.
- Platform target: desktop first, publish on itch.io.

## Collaboration Style
- Work step-by-step; do not jump ahead.
- Prefer execution mode and plan in very small increments while implementing.
- Propose small increments and wait for next instruction.
- Explain changes briefly and clearly.

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

## Verification
- After each code change, state exactly how to run and what to check.
- Call out known limitations and TODOs.

## Communication
- Be direct and concise.
- If blocked, ask one precise question.
