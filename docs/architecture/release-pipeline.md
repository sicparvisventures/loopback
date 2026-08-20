# Release & Deployment Pipeline

**Date:** 2026-08-21
**Status:** Live

Two independent pipelines, both driven by git.

## Web → Vercel

```
push to main ──▶ Vercel build (Root Directory: web) ──▶ production
open a PR    ──▶ Vercel build                      ──▶ preview URL
```

| | |
|---|---|
| Project | `reserve4you/loopback` (`prj_A5aNksQSTFnfDrhDxoOmUHFGqBJx`) |
| Root Directory | `web` |
| Production branch | `main` |
| Production URL | https://loopback-taupe.vercel.app |
| Framework | Next.js (auto-detected) |

No GitHub Action deploys the site — Vercel's own GitHub integration does,
which is why there is no `VERCEL_TOKEN` in repo secrets.

### Required environment variables

Set in Vercel → Settings → Environment Variables. **Not yet configured**; the
build succeeds without them but every Supabase call fails at runtime, because
`createClient()` reads them at module load.

| Variable | Scope |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development |
| `SUPABASE_SERVICE_ROLE_KEY` | Production only — never expose to the client |
| `NEXT_PUBLIC_APP_URL` | Production, Preview |

## Native → GitHub Releases

```
git tag v0.1.0 ──▶ release-native.yml ──▶ Loopback.app ──▶ GitHub Release
                        (macos-26)          zip + SHA256SUMS.txt
```

`.github/workflows/release-native.yml` also accepts a manual
`workflow_dispatch` with a version, for builds off-tag.

### What build-app.sh does, and why

SwiftPM emits a bare executable. macOS needs a **bundle** for a dock icon, for
TCC permission prompts to carry the app's usage descriptions, and for Launch
Services to recognise it at all. `scripts/build-app.sh` assembles that:

1. `swift build -c release --arch arm64 --arch x86_64` → universal binary.
2. `Loopback.app/Contents/{MacOS,Resources}` layout + `PkgInfo`.
3. Substitutes `$(EXECUTABLE_NAME)` in `Info.plist` — an Xcode build variable
   that only Xcode expands — and stamps the version.
4. Ad-hoc `codesign`. Without any signature macOS refuses to launch arm64
   binaries outright.
5. `ditto -c -k --keepParent` rather than `zip`, so the bundle survives.

### Credential injection

When the repo variable `SUPABASE_URL` and secret `SUPABASE_ANON_KEY` exist,
CI writes them into `Info.plist` before building, so a downloaded app is
connected out of the box. Without them the app ships unconfigured and asks in
**Settings → Supabase Connection**. See `SupabaseConfig.swift` for the full
resolution order.

## Installation paths

| Path | Gatekeeper | Notes |
|---|---|---|
| `curl … install.sh \| bash` | **none** | curl does not set `com.apple.quarantine` |
| Browser download from Releases | blocked on first launch | right-click → Open, or `xattr -dr com.apple.quarantine` |

Builds are ad-hoc signed, not notarised. To notarise later: obtain a Developer
ID certificate, add `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`, and the
signing certificate to repo secrets, then replace the ad-hoc `codesign` call
with a Developer ID signature plus `xcrun notarytool submit --wait` and
`xcrun stapler staple`.

## CI

`.github/workflows/ci.yml` runs on every push to `main` and every PR:

- **web** (ubuntu): `npm ci`, `npm run lint`, `next build` against placeholder
  Supabase env.
- **native** (macos-26): builds the full `.app` via the same script the release
  uses, and uploads it as a 7-day artifact. The release path is therefore
  exercised on every push, not discovered broken at tag time.

## Gotchas learned the hard way

- **macos-15 cannot build this.** supabase-swift declares
  `swift-tools-version:6.1`; the older toolchain rejects its language-mode
  settings, silently drops the `Realtime` target, and fails much later with
  "no such module 'Realtime'". Both jobs select the newest Xcode on the image.
- **`SupabaseClient.init` traps** on a URL that is not absolute http(s). Never
  construct one from unvalidated input.
- **`(dashboard)` is a route group**, not a path segment. `/dashboard/search`
  404s; the route is `/search`.
