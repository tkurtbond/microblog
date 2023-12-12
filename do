#! /usr/bin/env bash
PUBLISH=0
PUBGEMINI=1
PUBWWW=1
PUBUNWIND=1

errors=0

while getopts "ghpuw" opt
do
    case "$opt" in
        (\?) ((errors++)) ;;
        (g) PUBGEMINI=0 ;;
        (h) DO_HELP=1 ;;
        (p) PUBLISH=1 ;;
        (u) PUBUNWIND=0 ;;
        (w) PUBWWW=0 ;;
    esac
done

((DO_HELP)) && ERROUT=/dev/stdout || ERROUT=/dev/stderr

((DO_HELP || errors)) && {
    cat >$ERROUT <<EOF
usage: $0 [-tn]

Options:
-g      Don't publish to consp.org Gemini.
-h      Displays this message.
-p	Actually publish to my Gemini and WWW sites
-u      Don't publish to unwind-protect.org.
-w      Don't publish to consp.org WWW.
EOF
    exit
}
time ((echo "Building HTML";                                time ./build.sh) &&
      (echo "Building Atom feeds";                              time ./atom) &&
      ((PUBLISH))                                                            &&
      {
          ((PUBGEMINI)) &&
              (echo "rsyncing to consp.org gemini capsule"; time ./gconsprsync)
          ((PUBWWW)) &&
              (echo "rsyncing to consp.org website";         time ./consprsync)
          ((PUBUNWIND)) &&
              (echo "rsyncing to unwind-protect.org website";  time ./nfsrsync)
      })  \
          2>&1 | tee Log.do
