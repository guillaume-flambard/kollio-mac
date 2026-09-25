# L3 — tasks

The domain and the request path are in. The interface is not, and the difference is
stated on every line rather than blurred.

- [x] A source has a kind, a locator, a stable id and its revisions.
      `SourceLedgerTests`
- [x] A reference is a pointer, not a copy: a pasted link fetches nothing and an
      image is not understood until asked. `SourceLedgerTests`
- [x] A quote keeps a locator that survives the source moving, and a citation
      towards a source or revision that is not there is refused. `SourceLedgerTests`
- [x] A claim can be verified, and verification requires an observation and an
      author. There is no API that sets a badge without them. `SourceLedgerTests`
- [x] A new revision flags what it supersedes and never re-points a citation.
      `SourceLedgerTests`
- [x] A failed extraction keeps the previous good version active. `SourceLedgerTests`
- [x] A removed source never deletes the claim; the citation stays, marked.
      `SourceLedgerTests`
- [x] The context budget is measured on the real request path, omissions are
      counted, and a required item is never dropped to fit. `ContextProjectionTests`,
      `AppleAdapterTests`
- [x] A local-only projection cannot be sent. `ContextProjectionTests`
- [ ] A source is attached through a validated command in one transaction. The
      ledger exists and is correct; nothing mutates the document yet.
- [ ] Import and extraction: text, Markdown, PDF, CSV, image. **Not started.**
- [ ] A context view lists sources and quotes, reading only from the ledger.
- [ ] A knowledge view is derived, never authored twice.
- [ ] Retrieval returns its result *and* its absence.
- [ ] A presentable object carries an external link that opens outside the app.
- [ ] The interface that shows the projection matches the built payload. The
      payload is measured and reported; nothing shows it to a person yet.

## Design pressure worth recording now

`AI-12` is the lot's hardest item and has no code. On-device context is measured
at 8192 tokens, and the real Apple run already sits at 9 to 15 seconds cold. A
retrieval step that grows the prompt will make that worse before it makes the
product better, so budgeting belongs in this lot rather than after it.
