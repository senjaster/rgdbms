#!/bin/sh

set -x
ydb -p default sql -s 'SELECT count(*) FROM stock'
set +x
