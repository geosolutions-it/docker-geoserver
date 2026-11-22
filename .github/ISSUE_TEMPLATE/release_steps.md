---
name: docker-geoserver release
about: Steps to follow for a docker-geoserver release
title: ''
labels: 'internal'
assignees: ''
---

- [x] Create an issue with this checklist in the release milestone, named "Release x.x.x".
- [ ] Create the milestone and the new branch (both with the same semver format).
- [ ] Run the "Generate changelog and create release" manual workflow on this new branch to generate the changelog. It also creates a github release in draft mode.
- [ ] Edit the github release if needed and publish it
- [ ] Create a PR to master from the release branch and merge it.
- [ ] Close this issue.
- [ ] Close the milestone.
