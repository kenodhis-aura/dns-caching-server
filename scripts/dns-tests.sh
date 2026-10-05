#!/bin/bash

DNS_SERVER="192.168.122.100"

echo "=== DNS Server Test ==="
dig @"$DNS_SERVER" google.com

echo
echo "=== DNS Cache Test ==="
echo "First query:"
dig @"$DNS_SERVER" redhat.com +stats

echo
echo "Second query:"
dig @"$DNS_SERVER" redhat.com +stats

echo
echo "=== DNSSEC Validation Test ==="
dig @"$DNS_SERVER" dnssec-failed.org
