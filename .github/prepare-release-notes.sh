#!/bin/bash
sed "s/\${VERSION}/${VERSION}/g" .github/release-template.md > /tmp/release-notes.md
cat /tmp/release-notes.md
