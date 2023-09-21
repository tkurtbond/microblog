#! /usr/bin/env bash
time ((echo "Building HTML";                                time ./build.sh) &&
      (echo "Building Atom feeds";                              time ./atom) &&
      (echo "rsyncing to consp.org gemini capsule";      time ./gconsprsync) &&
      (echo "rsyncing to consp.org website";              time ./consprsync) &&
      (echo "rsyncing to unwind-protect.org website";      time ./nfsrsync))  \
          2>&1 | tee Log.do
