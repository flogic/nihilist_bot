#!/bin/sh
#
# Filters through logs, looking for error messages. Run this command to get a
# quick overview on whether your leaves are encountering errors or not.

echo "==== ERROR-LEVEL LOG MESSAGES ===="
grep Error log/*.log
echo
echo "====   UNCAUGHT EXCEPTIONS    ===="
grep ERROR autumn-leaves.log
echo
echo "====     OUTPUT TO STDOUT     ===="
tail -5 autumn-leaves.output
