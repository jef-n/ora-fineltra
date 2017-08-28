#!/bin/bash

[ -n "$DB" ] || exit 1

# See http://blog.sogeo.services/blog/2015/10/04/bezugsrahmenwechsel-st-fineltra-in-action.html
wget -O chenyx06.sqlite "https://drive.google.com/uc?export=download&id=0B6Qb5JteUzxLRUtwLVhWVkdpdDQ"

ogr2ogr -f OCI "OCI:$DB:" chenyx06.sqlite chenyx06_lv03
ogr2ogr -f OCI "OCI:$DB:" chenyx06.sqlite chenyx06_lv95

sqlplus $DB @install
