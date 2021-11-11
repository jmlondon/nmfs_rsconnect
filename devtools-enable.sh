#!/bin/bash

echo arguments: "$@" >&2
echo >&2

source scl_source enable devtoolset-10

exec "$@"