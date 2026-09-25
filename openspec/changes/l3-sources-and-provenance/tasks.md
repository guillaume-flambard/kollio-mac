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
- [x] A source is attached through a validated command in one transaction, and a
      transaction that fails halfway attaches nothing. `SourceCommandTests`
- [x] Intelligence is refused `attachSource`, `addCitation`, `recordVerification` and
      `removeSource` outright. A model that could add a citation would manufacture the
      appearance of support, and one that could record a verification could award
      itself a badge. `SourceCommandTests`
- [x] A chip on the claim shows what state its sources are in, one per source, read
      from the ledger and never cached. `SourceChipTests`
- [x] A file with no text cannot be imported as a good revision, and the previous
      version stays active. `SourceCommandTests`
- [x] The `.kollio` schema declares the ledger, the version is bumped to 2, and a
      test fails if the codec writes a key the schema does not declare.
- [ ] Choosing a file, reading it, and importing its text. **Not started.** The chip
      can only report what the ledger already holds.
- [ ] Opening a citation back at its passage.
- [ ] Recording a verification from the interface. The command exists and is tested;
      nothing in the app calls it.
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
