# Stormcrow

> Here you come again! And with you come evils worse than before, as might be
expected.

> Why should I welcome you, Gandalf Stormcrow? Tell me that.

> &mdash; *The Two Towers*, JRR Tolkien

The Stormcrow library contains implementations of common cryptographic
primitives in the Nim programming language, with an emphasis on secure real-time
communication. Stormcrow is being written primarily as a learning exercise for
Nim (because that's clearly working out so well for OpenSSL...), but it uses
well-vetted algorithms and implementations that are simple enough to be audited
and tested easily.

### Currently Implemented Features:

- Salsa20
- OS-specific CSPRNG (`/dev/urandom` or `CryptGenRandom()`)

### Currently Planned Features:

- Blake2
- Curve25519

I'm sure that I look like a djb freak, but the choices of algorithms are pretty
standard.
