# L4 — I come back to it

## Why

An idea is not finished when it is generated. It is finished when it has been
checked, and it must survive being closed for a month.

## What changes

- Verification as a first-class record: what was checked, when, and how.
- Resume: a document reopens on its own last view, not on an empty canvas.
- Durable memory of a direction, including a rejected one.
- Export and import as a human-readable file, with a format that is not the
  working format.
- Local backup of the document, kept on the user's machine.

## What it does not change

A rejected direction is never deleted. That is invariant 4 and this lot is where
it is most easily broken.

## Features

DOC-05 … DOC-08, DEC-04 … DEC-06
