# ARES

Analytical Robotics Evaluation System — FTC team statistics, OPR analysis and match simulation.

This is the monorepo. Every component is its own repository, wired in as a submodule.

```
FIRST API ──▶ db ──▶ Supabase ──▶ bot / site / app
                 ╲            ╱
                  ╲── model ─╱
```

| Submodule | Language | What it is |
|---|---|---|
| [`model`](https://github.com/ares-hq/model) | Rust | Shared types, FIRST and Supabase clients, table names |
| [`db`](https://github.com/ares-hq/db) | Rust | Pipeline: FIRST API → OPR solve → rank → Supabase |
| [`bot`](https://github.com/ares-hq/bot) | Rust | Discord bot: team stats, match predictions, live match results |
| [`site`](https://github.com/ares-hq/site) | TypeScript | Web front end |
| [`app`](https://github.com/ares-hq/app) | TypeScript | Mobile app |

## Development

```bash
git clone https://github.com/ares-hq/ares.git && cd ares
git submodule update --init model db bot
cargo test --workspace
cargo clippy --workspace --all-targets
```

The Rust crates share one workspace, which points `db` and `bot` at the local `model` checkout, so a `model` change can be tested against both before it is published. Both binaries read a gitignored `.env` here; [`db`](db/README.md) and [`bot`](bot/README.md) list the keys.

With [mold](https://github.com/rui314/mold), an uncommitted `.cargo/config.toml` speeds up linking:

```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

Deployment: [`deploy/README.md`](deploy/README.md).
