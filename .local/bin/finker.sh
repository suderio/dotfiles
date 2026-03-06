# Stop on error
set -e
# Stop on unitialized variables
set -u
# Stop on failed pipes
set -o pipefail

# Trap exit to allow error handling
trap 'catch $? $LINENO' EXIT

catch() {
  if [ "$1" != "0" ]; then
      echo "Error $1 occurred on $2"
      echo "Finker Error: $1"
    else
      echo "Finker End"
  fi
}

echo "Finker Begin"
# create temporary file
tmpfile=$(mktemp /tmp/finker.XXXXXX)
resultfile=$(mktemp /tmp/finker.XXXXXX)

# create file descriptor 3 for writing to a temporary file so that
# echo ... >&3 writes to that file
exec 3>"$tmpfile"
exec 5>"$resultfile"

# create file descriptor 4 for reading from the same file so that
# the file seek positions for reading and writing can be different
exec 4<"$tmpfile"
exec 6<"$resultfile"

# delete temp file; the directory entry is deleted at once; the reference
# counter
# of the inode is decremented only after the file descriptor has been closed.
# The file content blocks are deallocated (this is the real deletion) when the
# reference counter drops to zero.
rm "$tmpfile"

# Gets all images from registry
REGISTRY="$1"

echo "Finker reading images from ${REGISTRY}"
curl -ksL "https://${REGISTRY}/v2/_catalog?n=1000000"\
  |yq -P .repositories\
  |cut -d" " -f2\
  |while read -r i; do curl -kLs "https://${REGISTRY}/v2/$i/tags/list"; done >&3

echo "Finker printing Images"

# todo loop through tags
while read -r i
do
  echo "$i" | yq '"docker://registry.bndes.net:5000/" + .name + ":" + .tags.[]' \
    | while read -r j; do skopeo --debug inspect --no-creds --tls-verify=false "$j"| yq .Digest | cat <(echo "$j") - >&5; done >&5
done <&4

echo "Finker printing Digests"
cat <&6

# close the file descriptor (done automatically when script exits)
# see section 2.7.6 of the POSIX definition of the Shell Command Language
exec 3>&-
exec 5>&-
