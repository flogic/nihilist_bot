#!/bin/sh
#
# Generates the documentation for Autumn Leaves and your leaves. Documentation is
# in HTML format and will be in the doc/ folder.

rm -Rf doc
rdoc -m README --title "Autumn Leaves Documentation" libs leaves README support genesis.rb big-switch.rb
