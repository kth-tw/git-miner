#! /bin/sh

GIT_AMEND=''
MESSAGE=''
GIT_HEAD='HEAD'

# parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  --amend )
    GIT_AMEND='--amend'
    GIT_HEAD='HEAD^'
    ;;
  -m | --message )
    MESSAGE="$2"
    shift
    ;;
  -l | --leader )
    LEADER="$2"
    shift
    ;;
  * )
    echo "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done

DATE=$(date +"%s")
TIMEZONE=$(date +"%z")
GIT_TREE=$(git write-tree)
GIT_AUTHOR="$(git config --get user.name) <$(git config --get user.email)>"
if (git --no-pager show $GIT_HEAD > /dev/null 2> /dev/null); then
  GIT_PARENT="parent $(git --no-pager show --quiet --format='%H' $GIT_HEAD)\n"
else
  GIT_PARENT=""
fi

while true
do
  NONCE=$(openssl rand -hex 8)

  GIT_FILE="tree $GIT_TREE\n${GIT_PARENT}author $GIT_AUTHOR $DATE $TIMEZONE\ncommitter $GIT_AUTHOR $DATE $TIMEZONE\n\n$MESSAGE\n\nNONCE=0x$NONCE"

  HASH=$(echo "commit $(echo $GIT_FILE | wc -c | xargs)\0$GIT_FILE" | sha1sum)

  [[ $HASH == ${LEADER}* ]] && break
done

export GIT_COMMITTER_DATE=$DATE
git commit $GIT_AMEND --no-gpg-sign -m "$MESSAGE" -m "NONCE=0x${NONCE}" --date $DATE --allow-empty