#!/bin/bash
set -eou pipefail

echo "Which EC2 instance to deploy?"
echo -n "[1] Ubuntu [2] RHEL [3] Windows: "
read -r ans
case "$ans" in
    1)
        pushd ubuntu
            summon -p summon-conjur -f ../secrets-new.yml terraform apply
        popd
        ;;
    2)
        echo "Under development"
        ;;
    3)
        echo "Under development"
        ;;
    *)
        echo "Please make a valid selection."
        exit
        ;;
esac