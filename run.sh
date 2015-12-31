#!/bin/bash

set -euo pipefail

input=$1

rm "${input}-1-1.xml"
rm "${input}-2-1.xml"
rm "${input}-3-1.xml"
rm "${input}.svg"
java -Xmx1g -Xss300m -jar Transform.jar \
    --location . \
    --source "${input}.xml" \
    --dest .
