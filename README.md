**English** · [Русский](README.ru.md)

# seedsplit

Split a secret across shares with Shamir Secret Sharing — no "unbreakable" snake oil.

[![CI](https://github.com/Di-kairos/seedsplit/actions/workflows/ci.yml/badge.svg)](https://github.com/Di-kairos/seedsplit/actions/workflows/ci.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS-blue)
![shellcheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)

Part of the [Paranoid Tools](https://github.com/Di-kairos/paranoid-tools) ecosystem.

## Why

Split a seed phrase, password or key into N shares so that any T of them reconstruct
the secret, while T-1 shares reveal **nothing** about it. That way no single medium or
backup is a single point of failure or compromise: lose one sheet and the secret
survives; find one sheet and you learn nothing.

## Install

The installer pulls the binary **and `SHA256SUMS` from the release tag** (not from a
moving `main` branch) and verifies the checksum **before** installing — it fails closed
on any mismatch.

### Verify-then-run (don't trust, verify)

Piping any script into a shell means running code you haven't read. Prefer this —
download, check the checksum, read it, then run:

```bash
base=https://github.com/Di-kairos/seedsplit/releases/latest/download
curl -fsSLO "$base/install.sh"
curl -fsSLO "$base/SHA256SUMS"
shasum -a 256 -c SHA256SUMS --ignore-missing   # verifies install.sh
less install.sh                                  # read it
bash install.sh
```

### One-line install via curl

```bash
curl -fsSL https://github.com/Di-kairos/seedsplit/releases/latest/download/install.sh | bash
```

> **Integrity vs authenticity (honest scope).** The checksum proves the downloaded
> binary matches the `SHA256SUMS` published in the **same release** — it catches
> corruption, partial/cached tampering, and stops you running code off the moving `main`
> branch. It does **not** by itself defeat an attacker who can rewrite *both* the binary
> and its checksum at the source (or your connection), nor does it prove *who* published
> them. Pin a specific version with `SEEDSPLIT_VERSION=0.2.0` instead of `latest` for
> reproducibility. Override the source with `SEEDSPLIT_BASE_URL` and the install path
> with `SEEDSPLIT_DEST`.

### Language

Output is English by default. For Russian, set `ST_LANG=ru` (the tool also honors a
Russian system locale automatically).

## Usage

The secret is read from **stdin** or `--file`, **never** from argv (argv is visible in
`ps`).

Split a secret into 5 shares with a threshold of 3 (any 3 reconstruct it; any 2 reveal
nothing):

```bash
$ printf '%s' "legal winner thank year wave sausage worth useful legal winner thank yellow" \
    | seedsplit split -n 5 -t 3
SSS1-3-1-b968a37b9e645e3f...0b5b5dd90947f1649d110f4ea74e177df8f44-8b1c
SSS1-3-2-ceb46aba434ed581...9aaa9bcb-cbd9
SSS1-3-3-22dc82adb84dead2...022c5a-8b11
SSS1-3-4-03f88c162889179a...7b81075-ea44
SSS1-3-5-ef906401d38a28c9...f10a7e4-1446
```

Each line is a self-contained share in the form `SSS1-<T>-<x>-<hexY>-<chk4>`: format
version, threshold, point index, body, and a 4-char checksum (catches a typo in that one
share). Distribute the lines across different media/locations.

Reconstruct the secret — feed **any T (or more) shares** on stdin, one per line:

```bash
$ head -3 shares.txt | seedsplit combine
legal winner thank year wave sausage worth useful legal winner thank yellow
```

You can also pass shares as file arguments:

```bash
seedsplit combine share1.txt share2.txt share3.txt
```

Version and help:

```bash
seedsplit version        # or -v / --version
seedsplit help           # or -h / --help
```

### Commands & flags

| Command | What it does |
|---|---|
| `seedsplit split [-n N] [-t T] [--file F]` | Split a secret (from stdin or `--file`) into `N` shares; any `T` reconstruct it. Default `-n 3 -t 2`. |
| `seedsplit combine [FILE...]` | Reconstruct the secret from ≥T shares (read from stdin, one per line, or from `FILE`s). |
| `seedsplit version` | Print the version (also `-v` / `--version`). |
| `seedsplit help` | Print help (also `-h` / `--help`). |

Parameter limits: the threshold `-t` must be ≥2 (otherwise one share equals the whole
secret), `-n` must be ≥ `-t` and ≤255 (evaluation points in GF(256)); the secret may be
up to 65535 bytes.

## How it works

A pure implementation of **Shamir Secret Sharing over GF(256)** (the `2^8` field with
reducing polynomial `0x11b`, same as AES; addition = XOR, multiplication via log/antilog
tables from generator `0x03`). The random polynomial coefficients come from
`/dev/urandom`.

The secret is wrapped in an integrity header (`0x55` | length | secret | CRC from
sha256), so `combine` returns **either the exact secret or an honest refusal** —
corrupted shares or a set from different secrets won't pass validation silently.

## Scope & limitations

Honesty is the whole point of this ecosystem, and Shamir sharing is especially easy to
oversell. So here are the honest limits:

- **share quality = RNG quality** — we use `/dev/urandom`, not a homegrown PRNG;
- **a secret in `argv` is visible in `ps`** — input is via stdin/file only, never an
  argument;
- **shares are only as safe as how you STORE and DISTRIBUTE them;** the threshold
  protects against a leak of fewer than T shares, but not against the LOSS of ≥(N-T+1)
  shares — geography and media are your responsibility;
- **there is NO interoperability with SLIP-39 / hardware wallets yet** — a full SLIP-39
  (1024-word list + RS1024 + encryption) is a separate effort in scope, not "zero
  dependencies"; it's honestly flagged as a scope decision for a later pack.

## Architecture

- Single-file Bash, zero dependencies. Shamir over GF(256) is implemented in pure Bash;
  the RNG is `/dev/urandom`. Tests: **bats** (31 tests — `split`/`combine`/round-trip,
  threshold validation, honest refusal on corrupted and incompatible sets).
- The shared core (`lib/common.sh`) is **vendored** inline from securetrash, pinned to a
  git ref; `tools/vendor-common.sh --check` catches drift in CI. See
  `paranoid-tools/README.md`.

## Windows equivalent

Planned second: the same Shamir over GF(256) in PowerShell, with
`RNGCryptoServiceProvider` instead of `/dev/urandom`. The port follows securetrash.

## License

[MIT](LICENSE). Security issues — see [SECURITY.md](SECURITY.md); how to contribute —
[CONTRIBUTING.md](CONTRIBUTING.md).

This software is provided "as is," without warranty of any kind. seedsplit splits a
secret correctly (a real Shamir threshold), but it is **not** responsible for how you
store and distribute the shares — that's on you.
