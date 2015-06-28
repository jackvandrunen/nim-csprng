# Stormcrow

> Here you come again! And with you come evils worse than before, as might be
expected.

> Why should I welcome you, Gandalf Stormcrow? Tell me that.

> &mdash; *The Two Towers*, JRR Tolkien

The Stormcrow library is a pure Nim library designed for authenticated
encryption and key exchange, with an emphasis on real-time communication.
Stormcrow uses well-vetted standards from the crypto community, and the
implementations are designed to be simple enough to be audited and tested
easily.

### Currently Implemented Features:

- Salsa20
- OS-specific CSPRNG (`/dev/urandom` or `CryptGenRandom()`)

### Currently Planned Features:

- Blake2
- Curve25519

I'm sure that I look like a djb freak, but the choices of algorithms are pretty
standard.
