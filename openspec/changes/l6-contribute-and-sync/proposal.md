# L6 — two people, one document, no lost work

## Why

Concurrency is where a shared document either becomes trustworthy or becomes a
source of silent loss. It comes after L5 for that reason.

## What changes

- Concurrent edits detected and refused clearly, never merged silently.
- Offline changes queued and reconciled, with the conflict shown to a person.
- A single authoritative copy, with a stated owner for the document.

## What it does not change

The core stays local-first. Sync is a transport concern layered above a document
that is already correct on one machine.

## Features

TEAM-06, TEAM-08 … TEAM-11, DEC-04 … DEC-06
