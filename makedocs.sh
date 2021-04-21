#!/bin/bash

# This script builds the internal source documentation.
SOURCES=src/*.pas
SRCSYNT=src/syntax/*.pas
OUTPUT_DIR=docs/internal/src/
EXT_HIERARCHY=--external-class-hierarchy=pasdoc-inheritance.txt

pasdoc -T mlsde -O html -L en --use-tipue-search --include-creation-time -E "$OUTPUT_DIR" $EXT_HIERARCHY "$SOURCES" "$SRCSYNT"
