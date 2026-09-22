<!--
PR title must follow Conventional Commits (e.g. `feat:`, `fix:`, `chore:`).
The pr_title.yml workflow will fail the check otherwise.
-->

## Summary

<!-- 1–3 sentences. What changed and why? -->

## Type of change

- [ ] Bug fix (`fix:`)
- [ ] New feature (`feat:`)
- [ ] Refactor / cleanup (`refactor:`)
- [ ] Docs / dartdoc (`docs:`)
- [ ] Tests only (`test:`)
- [ ] CI / tooling (`ci:` / `chore:`)
- [ ] Breaking change

## Linked issues

<!-- Use "Closes #N" so the issue auto-closes on merge. -->

Closes #

## Test plan

<!-- How did you verify? Paste relevant test names or manual steps. -->

- [ ] `fvm flutter analyze .` passes
- [ ] `fvm flutter test` passes
- [ ] Manually verified in `example/` — the Android emulator covers the single-SIM
      path; dual-SIM, eSIM, roaming and anything on iOS need a real device

Device(s) tested on:

<!-- e.g. Pixel 7 / Android 15 / dual SIM, iPhone 13 / iOS 18 / eSIM -->

## Checklist

- [ ] New behavior is covered by a test in `test/`
- [ ] New public APIs have dartdoc comments
- [ ] Platform payload changes are mirrored in both `android/` and `ios/` where applicable
- [ ] No new permissions added to the plugin's `AndroidManifest.xml` (it is deliberately empty)
- [ ] PR title follows Conventional Commits

<!-- Version and CHANGELOG are handled by release-please. Don't bump them by hand. -->
