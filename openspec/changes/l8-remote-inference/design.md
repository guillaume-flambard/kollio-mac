# L8 — design decisions

## One seam, two providers, always distinguishable

**Chosen:** the same protocol, with the provider named in the result.

**Rejected:** a transparent fallback. A proposal that came from the network must
never be mistakable for one that came from the machine, or the user is being told
something false about where their context went.

## The server is preserved, not required

**Chosen:** a local-only path that is complete on its own.

**Rejected:** routing everything through a server for uniformity. The single-player
case is the product; the server is an option.
