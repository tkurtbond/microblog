#! /usr/bin/env bash
time ((echo "Building HTML";       time ./build.sh) &&
      (echo "Building Atom feeds"; time ./atom) &&
      (echo "rsyncing HTML to nfs.net"; time ./nfsrsync) &&
      (echo "rsyncing HTML to consp.org"; time ./consprsync) && 
      (echo "rsyncing gemtext to consp.org"; time ./gconsprsync)) 2>&1 |
    tee Log.do
