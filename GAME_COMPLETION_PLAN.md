# Spangle — Completion Plan

## Product target

Spangle 1.0 is a polished, offline-first Spanish learning game for iPhone, iPad, and Mac. It should feel complete without an account, network service, paid content, or downloaded art. QueKit and QYayKit remain optional ecosystem integrations; built-in campaign play must stand on its own.

The work is ordered as requested: **gameplay first, learning second, then the rest of the product**. “Complete” means every launch-to-play-to-results loop is understandable, replayable, persistent, accessible, tested, and recoverable.

## Baseline (the existing 20%)

The repository already contains a strong prototype:

- A one-touch, variable-height auto-runner with hazards, gaps, springs, coins, gates, and a finish.
- Twelve progressively unlocked campaign themes plus QueKit list import and generated lists.
- Mid-level and final multiple-choice quizzes, optional stars, persistent best star ratings, and themed procedural scenery.
- iPhone, iPad, and Mac targets, an app icon, and initial model tests.

The remaining work is not just “more levels.” It is the systems that turn the prototype into a dependable game: deterministic runs, fair recovery, game feel, multiple reasons to replay, meaningful learning progress, onboarding, settings, accessibility, robust persistence, and broad tests.

## Phase 1 — Gameplay foundation

### 1.1 Fair and replayable runs

- Make generated layouts deterministic for a selected level and run seed, including vocabulary order.
- Add pause/resume and automatically pause when the app becomes inactive.
- Add midpoint checkpoints; a failed attempt can restart from the latest checkpoint with the exact collected-item state restored.
- Add a protective shield pickup that absorbs one hazard hit and grants brief invulnerability.
- Add a moving enemy obstacle to later difficulty tiers without changing the one-touch control scheme.
- Keep ordinary campaign retries available from the beginning.

### 1.2 Game feel and goals

- Add score and collection combo, with rewards for words, challenge stars, checkpoints, and correct answers.
- Add clear HUD state for score, combo, shield, progress, vocabulary, and stars.
- Add procedural sound cues and optional haptics for jumps, pickups, answers, damage, and completion.
- Preserve the current short-hop/long-hop input on touch, click, Space, and Up Arrow.

### 1.3 Replay modes

- Add a deterministic daily challenge assembled from the campaign vocabulary.
- Add a long-form marathon assembled from all built-in themes.
- Persist daily and all-time best scores locally.
- Keep imported QueKit levels as standalone always-unlocked runs.

## Phase 2 — Learning system

### 2.1 Better questions

- Quiz in both directions: Spanish → English and English → Spanish.
- Generate up to four unique, plausible choices from the active vocabulary.
- Keep gate questions limited to collected, not-yet-quizzed words.
- Ensure the final quiz covers every active word exactly once.
- Show clear correct/incorrect feedback while preserving the game’s consequence for wrong answers.

### 2.2 Persistent mastery

- Store per-word exposures, correct answers, mistakes, streak, mastery level, and last-practised date using stable vocabulary identifiers.
- Prefer weaker words and the less-practised translation direction when choosing review questions.
- Add a dedicated review session reachable from the menu.
- Add a learning dashboard with mastered, learning, due-for-review, accuracy, and total-answer counts.

### 2.3 Useful results

- Track run duration, score, words collected, quiz accuracy, mistakes, stars, and checkpoint use.
- Show a results card after each completed level or challenge.
- Surface newly mastered words and a recommended next action.

## Phase 3 — Complete app experience

### 3.1 First-run and navigation

- Add a concise first-run tutorial covering hold-to-jump, word coins, gates, stars, shields, and checkpoints.
- Add Settings and Learning Progress from the main menu.
- Make menu sections distinguish Campaign, My QueKit Lists, and Challenge Modes.
- Add reset controls for campaign progress, ratings, scores, and learning history with confirmation.

### 3.2 Accessibility and preferences

- Add independent sound and haptic toggles.
- Add reduced-motion support and an optional high-contrast gameplay mode.
- Add accessibility labels, hints, values, keyboard shortcuts, Dynamic Type-friendly overlays, and non-colour-only state indicators.
- Respect system Reduce Motion by default.

### 3.3 Reliability and shipping

- Unit-test deterministic generation, level safety invariants, checkpoint state, scoring, quiz construction, mastery updates, and persistence.
- Add UI smoke coverage for menu → intro → pause and quiz/results flows where practical.
- Verify both iOS Simulator and macOS builds and run the game interactively.
- Keep README, controls, architecture, and release notes current.
- Ship without analytics, ads, accounts, or network dependence. Game Center, cloud progress sync, localization beyond the Spanish/English teaching content, and monetization are post-1.0 integrations because they require product, privacy, entitlement, and translation decisions.

## Acceptance criteria

A 1.0 candidate is ready when:

1. A new player can understand and start a level without outside instructions.
2. Every campaign level can be replayed deterministically, paused, recovered from a checkpoint, completed, and scored.
3. Learning performance survives relaunch and drives a playable review session.
4. Campaign, daily, marathon, imported-list, settings, progress, failure, and completion flows all have a clear route back to the menu.
5. Core model tests pass and the app builds and launches on iOS and macOS.

## Implementation record

### Delivered in this completion pass

- [x] Seeded deterministic level/vocabulary layouts and stable vocabulary identity.
- [x] Pause/resume, inactive-app pausing, midpoint checkpoint restoration, shields, and patrolling enemies.
- [x] Score/combo HUD, run summaries, procedural sound, haptics, daily challenge, marathon, and local best scores.
- [x] Bidirectional four-choice questions, correction feedback, final-quiz coverage, and adaptive review sessions.
- [x] Persistent per-word exposure/answer/mastery/due history and a learning-progress dashboard.
- [x] First-run tutorial, settings/reset confirmation, high contrast, reduced SwiftUI motion, and accessibility labels/values.
- [x] Updated product documentation and 16 model tests covering deterministic generation, safety mechanics, queues, questions, identity, persistence, mastery ordering, reset, and results.
- [x] Tuist regeneration, macOS tests/build, iOS Simulator build/launch, and signed physical-device installation.

### Explicit post-1.0 integrations

- [ ] Game Center leaderboards/achievements and cloud progress sync.
- [ ] Additional UI localization and professionally authored audio/art packs.
- [ ] Accounts, social features, monetization, and privacy-reviewed analytics.

These integrations are isolated from the offline 1.0 because each needs product policy, entitlements or backend operations, privacy decisions, and—in the case of localization—human translation review. The core game does not depend on them.
