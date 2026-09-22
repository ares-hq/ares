# Deployment

CI builds both binaries; the server only downloads them. Nothing is compiled on the
host, so it needs no Rust toolchain, no container runtime and no checkout of this repo.

```
/usr/local/bin/ares-bot        supervised by systemd, restarts on crash
/usr/local/bin/ares-db         one-shot, driven by two timers
/usr/local/lib/ares/update.sh  hourly: pulls the newest release, restarts the bot
/etc/ares/env                  every secret, 0600 root-only
/var/lib/ares/                 installed release tag, pipeline lock
```

## Install

```bash
scp -r deploy ares:~/
ssh ares 'sudo bash ~/deploy/install.sh'   # writes a blank /etc/ares/env, then stops
ssh -t ares 'sudo -e /etc/ares/env'
ssh ares 'sudo bash ~/deploy/install.sh'   # installs the release, starts everything
```

`/etc/ares/env` holds the keys from [`db/README.md`](../db/README.md) and
[`bot/README.md`](../bot/README.md), and nothing else. Releases are public, so the updater
carries no credential — the server only ever reads from GitHub.

## Schedule

| Unit | When | What |
|---|---|---|
| `ares-bot.service` | always | Discord bot, `Restart=always` with a 10 s backoff |
| `ares-db.timer` | `*:0/15` | Recent events only — the default incremental pass |
| `ares-db-full.timer` | 04:00 UTC | `--all-events`, repairs drift in earlier events |
| `ares-update.timer` | hourly | New release → install and restart the bot |

Both pipeline units take the same `flock`, so a slow pass delays the next one instead of
overlapping with it. A failed pass is not retried: it is almost always a credential
problem or an upstream outage, and the next tick is the retry. Transient failures are
already handled a level down, where requests back off and honour `Retry-After`.

## Releases

Every push to `main` runs `.github/workflows/release.yml`: fmt, clippy and the test suite,
then a static musl build tagged `build-<n>` with one asset,
`ares-x86_64-linux-musl.tar.gz`. The hourly timer picks it up within the hour; to take it
immediately:

```bash
sudo systemctl start ares-update.service
```

To roll back, mark an older release as latest on GitHub and run the same command — the
installed tag is in `/var/lib/ares/release`.

## Checking on it

```bash
systemctl status ares-bot.service
journalctl -u ares-bot.service -f
journalctl -u ares-db.service --since today
systemctl list-timers 'ares-*'
```

## Running a pass by hand

```bash
sudo systemctl start ares-db.service        # the incremental pass, now
sudo systemctl start ares-db-full.service   # the full sweep, now
```

A past season is a one-off, so run it directly rather than adding a unit:

```bash
sudo systemd-run --pty --collect --uid=ares \
    --property=EnvironmentFile=/etc/ares/env \
    /usr/local/bin/ares-db --year 2024 --all-events
```
