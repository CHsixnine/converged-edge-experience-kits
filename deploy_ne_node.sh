source scripts/ansible-precheck.sh

ansible-playbook -vv \
    ./ne_node.yml \
    --inventory inventory.ini
