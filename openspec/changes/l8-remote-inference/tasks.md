# L8 — tasks

Partly implemented, and the honest state is narrower than it looks.

- [x] A `SuggestionService` seam exists, with a remote implementation behind it.
- [x] The server snapshot exists and the remote path was exercised against a
      mocked provider.
- [ ] A person chooses local or remote, and the choice is visible at the moment of
      use, not in a settings screen nobody opens.
- [ ] What may leave the machine is stated before it leaves it.
- [ ] A remote failure is reported as a remote failure. It must never render as
      local output, which is the failure mode invariant 7 exists to prevent.
- [ ] A key, if any, never enters the document and never enters a log.

## The gap worth naming

The seam exists and the mocked round trip passes, but nothing in the product
currently lets a person *see* which provider produced a proposal. The
architecture is ready and the interface is not, so the honest status is
`inProgress` rather than `implemented`.
