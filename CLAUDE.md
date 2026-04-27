# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Scratch org setup (creates org, deploys, assigns permset, opens browser)
./scripts/setup.sh [alias]              # default alias: practical-exam

# Seed data
sf apex run --file scripts/apex/seed.apex

# Deploy / retrieve source to the default org
sf project deploy start
sf project retrieve start

# LWC Jest
npm test                                # all LWC unit tests
npm run test:unit:watch
npm run test:unit:debug
npm run test:unit -- path/to/spec.js    # single test file

# Lint / format
npm run lint                            # eslint on aura + lwc
npm run prettier                        # format (apex, lwc, xml, md, etc.)
npm run prettier:verify
```

Husky + lint-staged run prettier, eslint, and `sfdx-lwc-jest --findRelatedTests` on staged files at commit time.

## Architecture notes

- **SFDX source format**, API version 66.0, single package directory at `force-app/`. Scratch-org definition is `config/project-scratch-def.json`.
- The `.forceignore` is tuned for this repo — check it before adding new metadata types.
