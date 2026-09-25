# L5 — design decisions

## Consent is per purpose, not global

**Chosen:** a consent record names what it allows.

**Rejected:** a single "I agree" flag. It cannot be revoked in any meaningful
sense, because revoking it revokes everything and staying with it grants
everything.

## Sharing names a person, never a link

**Chosen:** a share targets an identity.

**Rejected:** a capability link. Anyone holding it is indistinguishable from
anyone invited, and it cannot be revoked without knowing who was told.
