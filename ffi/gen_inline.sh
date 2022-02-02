#!/bin/sh

INLINE_FILE=./lib/src/ffi/notcurses_inline_g.dart

dart run ffigen --config ./ffi/inline.yml

# remove lines definitions to Opaque structs because they are on notcurses ffi
sed -i.bak '/ffi.Opaque/d' ${INLINE_FILE}

# rename duplicate structs
sed -i.bak 's/\(ncplane\)[0-9]*/\1/g' ${INLINE_FILE}
sed -i.bak 's/\(ncdirect\)[0-9]*/\1/g' ${INLINE_FILE}
sed -i.bak 's/\(nctabbed\)[0-9]*/\1/g' ${INLINE_FILE}
sed -i.bak 's/\(notcurses\)[0-9]*/\1/g' ${INLINE_FILE}

# remove empty lines at the enf of the file
sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${INLINE_FILE}
