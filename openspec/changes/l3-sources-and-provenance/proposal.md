# L3 — my context has roots

## Why

A document that only holds what the user typed cannot be resumed, audited or
trusted. Every claim needs to point back to something: a file, a link, a quote.

## What changes

- Sources attached to a context, each with a provenance kind and a stable id.
- Quotes captured with a locator back into the source.
- Contexts, provenance and knowledge shown as views, and only from the store.
- Verification of a claim, and the record of what was verified.
- Retrieval on request, and the explicit absence of a result.
- Presentable objects carry a link, and are openable outside the app.

## What it does not change

The document protocol gains a source reference, not a source store. The
filesystem stays the user's; Kollio never copies a document it was not given.

## Features

CTX-02 … CTX-07, CAN-06, CAN-07, CAN-09, CAN-10, AI-05, AI-06, AI-11, AI-12
