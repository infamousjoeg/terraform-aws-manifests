#!/bin/bash
set -eou pipefail

echo "Which EC2 instance to terminate?"
echo -n "[1] Ubuntu [2] RHEL [3] Windows: "
read -r ans
case "$ans" in
    1)
        pushd tf_deploy/ubuntu
            summon -f ../../secrets.yml terraform destroy
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