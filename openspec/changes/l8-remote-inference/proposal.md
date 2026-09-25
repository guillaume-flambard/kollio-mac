# L8 — more than the local model can do

## Why

The on-device model is real and it is small. Some work needs more than it can do,
and the product already has a server that can be used without being required.

## What changes

- A remote provider behind the same seam, opt-in, explicit about which is which.
- A visible boundary: what may leave the machine, and what may not.
- Failure of the remote path reported as itself, never as a local result.

## What it does not change

Invariant 7. Local and cloud are never silently interchangeable, and an
unavailable remote model does not become local output.

## Features

AI-10
