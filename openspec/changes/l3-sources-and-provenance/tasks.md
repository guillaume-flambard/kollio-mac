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
- [x] A file is read from disk by kind, and says honestly what came out.
      `SourceReaderTests`
- [x] **AC01** a CSV with quotes, commas and newlines parses correctly.
- [x] **AC02** a PDF with no text layer is marked as having no text.
- [x] **AC03** a pasted link is never fetched, and the refusal happens before any
      file access rather than surfacing as "the file could not be opened".
- [x] An image is digested and nothing else: no description, no OCR.
- [x] An empty file, a non-UTF-8 file and an unreadable kind are each reported as
      what they are, never as an empty success.
- [x] A file chooser in the contextual actions of a claim. `NSOpenPanel`,
      cancellable, nothing read until a file is chosen.
- [x] Reading the chosen file and importing its revision in one transaction, so a
      file that cannot be read leaves nothing behind. `SourceChipTests`
- [x] A file with no text is attached and announced as *not read*, never as a
      successful import.
- [x] The same file twice is two sources keyed by content, not two copies of one.
- [x] A failed import is recorded rather than refused, so the chip can say so, and a
      usable earlier revision stays the one being read. `SourceLedgerTests`
- [ ] A native reader for a long PDF, and a CSV preview in the interface.
- [x] Opening a citation back at its passage, from the exact revision it was read
      against, beside the claim. `SourceChipTests`
- [x] Recording a verification from the interface, and only with an observation:
      an empty one is refused and the draft is kept. `SourceChipTests`
- [x] A page locator shows no passage rather than a slice of joined text that would
      point at the wrong place. `SourceChipTests`
- [x] A citation on a superseded revision says so in the interface.
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
