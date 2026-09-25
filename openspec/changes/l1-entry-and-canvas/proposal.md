# L1 — I start with my own context

## Why

The prototype opened on a scripted demonstration. A person could not begin with
their own situation, and two-finger scrolling did nothing at all. Both are the
difference between a demo and a product.

## What changes

- A launch with no stored document shows the initial input. A stored document is
  restored. An unreadable one is reported and its file left untouched.
- A typed sentence becomes a real context object, persisted before any
  intelligence is asked, and editable in place with a stable identity.
- Two-finger trackpad scrolling pans the canvas. A scroll inside a text field
  stays with the field.
- Save on quit, with a new document getting its own file so it cannot destroy the
  previous one.
- A collapsed direction can be reopened from a named action, not only a
  double-click.

## What it does not change

The canvas stays canvas-first. No sidebar, no panel, no permanent chrome. The
document format, the command system and the durable decisions are untouched.

## Features

DOC-01, DOC-02, DOC-03, DOC-04, CAN-01, CAN-02, CAN-03, CAN-04, CAN-05, CTX-01

## Evidence

See `tasks.md`. The human trackpad pass is still owed and is the one thing that
cannot be automated here.
