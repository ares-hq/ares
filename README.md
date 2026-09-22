# ARES

Analytical Robotics Evaluation System — FTC team statistics, OPR analysis and match
simulation.

This is the monorepo. Every component is its own repository, wired in as a submodule.

```
FIRST API ──▶ db ──▶ Supabase ──▶ bot / site / app
                 ╲            ╱
                  ╲── model ─╱
```

| Submodule | Language | What it is |
|---|---|---|
| [`model`](https://github.com/ares-hq/model) | Rust | Shared domain types, season arithmetic, table names, Supabase client |
| [`db`](https://github.com/ares-hq/db) | Rust | Pipeline: FIRST API → OPR solve → rank → Supabase |
| [`bot`](https://github.com/ares-hq/bot) | Rust | Discord bot: `/team`, `/match`, `/favorite`, `/help` |
| [`site`](https://github.com/ares-hq/site) | TypeScript | Web front end |
| [`app`](https://github.com/ares-hq/app) | TypeScript | Mobile app |

Data flows one way. `db` writes `season_<year>` and `matches_<year>`; everything downstream
reads them. The only coupling between the pipeline and its consumers is `model` — the types,
and the table names they both resolve through `model::tables`.

## Getting started

```bash
git clone https://github.com/ares-hq/ares.git
cd ares
git submodule update --init model db bot
cargo build --workspace
```

The three Rust crates form one Cargo workspace, so `cargo test --workspace` and
`cargo clippy --workspace --all-targets` cover all of them and they share a single
`target/` directory. `app` and `site` are JavaScript, stay outside it, and are not
initialised above.

Each crate is also usable on its own. Built standalone, `db` and `bot` resolve `model` from
its published branch; built here, the workspace root redirects that to the sibling checkout,
so a change to `model` can be tested against both consumers before it is published.

## Configuration

Both Rust binaries read a shared `.env` at this root. It is gitignored — see
[`db/README.md`](db/README.md) and [`bot/README.md`](bot/README.md) for the keys each one
needs.

## Running it

Both binaries are built by CI as static musl executables and published as one release
asset. The server downloads them — it compiles nothing and runs no container runtime. The
bot is supervised by systemd; the pipeline is a batch job on a timer.

```bash
sudo systemctl start ares-db.service   # one pipeline pass
journalctl -u ares-bot.service -f      # follow the bot
```

See [`deploy/README.md`](deploy/README.md) for install, schedule, updates and rollback.

## Development

```bash
cargo test --workspace
cargo clippy --workspace --all-targets
cargo fmt --all
```

Dev builds keep only line tables and compile dependencies at `opt-level = 2`; both knobs
are in the root [`Cargo.toml`](Cargo.toml). If you have
[mold](https://github.com/rui314/mold), an uncommitted `.cargo/config.toml` points cargo
at it:

```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

Every push to `main` runs fmt, clippy and the tests, then publishes a release.
