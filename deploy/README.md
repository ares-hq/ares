# Deployment

CI publishes both binaries as a GitHub release; the server only downloads them. The [units](systemd), [installer](install.sh) and [updater](update.sh) are the reference for what runs and when.

## Install

```bash
scp -r deploy ares:~/
ssh ares 'sudo bash ~/deploy/install.sh'   # writes a blank /etc/ares/env, then stops
ssh -t ares 'sudo -e /etc/ares/env'
ssh ares 'sudo bash ~/deploy/install.sh'   # installs the release, starts everything
```

## Operate

- **Update now:** `sudo systemctl start ares-update.service` (otherwise hourly).
- **Roll back:** mark an older release as latest on GitHub, then update now. The installed tag is in `/var/lib/ares/release`.
- **New season:** before its first pipeline pass, run `select create_season_tables(2027);` in the Supabase SQL editor.
- **Past season:**

  ```bash
  sudo systemd-run --pty --collect --uid=ares \
      --property=EnvironmentFile=/etc/ares/env \
      /usr/local/bin/ares-db --year 2024 --all-events
  ```
