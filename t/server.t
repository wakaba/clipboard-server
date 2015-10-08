#!/bin/bash
echo "1..1"

rootpath=$(cd `dirname $0`/.. && pwd)
($rootpath/perl -c $rootpath/bin/server.psgi && echo -e "ok 1\n") || echo -e "not ok 1\n"
