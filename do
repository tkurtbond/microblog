#! /usr/bin/env bash
time (time ./build.sh && time ./atom && time ./nfsrsync)
