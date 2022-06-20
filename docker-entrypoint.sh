#!/bin/bash

if ${GPG_GENERATE:-false} && [[ ! -d /data/.gnupg ]]; then
    cat >/data/.gnupg_gen <<-EOF
    %echo Generating GPG key
    %no-ask-passphrase
    %no-protection
    Key-Type: ${GPG_TYPE:-default}
    Key-Length: ${GPG_LENGTH:-default}
    Name-Real: ${GPG_REALNAME:-Aptly}
    Name-Email: ${GPG_EMAIL:-aptly@example.org}
    Expire-Date: ${GPG_EXPIRE:-0}
    %commit
    %echo Done
EOF
    gpg --gen-key --no-tty --batch /data/.gnupg_gen
    rm -f /data/.gnupg_gen

    mkdir -p /data/public
    gpg --export "${GPG_EMAIL:-aptly@example.org}" >/data/public/Release.pub

    chmod 0755 /data/public
    chmod 0644 /data/public/Release.pub
fi

exec /usr/bin/aptly "$@"
