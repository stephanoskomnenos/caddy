#!/usr/bin/env elvish

use os
use str

var latest_version = (curl "https://api.github.com/repos/caddyserver/caddy/releases/latest" | from-json)[tag_name]
var latest_version = (str:trim-prefix $latest_version 'v')

var current_version = (if (os:exists 'caddy_amd64') {
    var v = [(str:split ' ' (./caddy_amd64 version))][0]
    echo (str:trim-prefix $v 'v')
} else {
    echo 'caddy not found'
})

if (==s $latest_version $current_version) {
    echo 'there is nothing to do'
    exit
}

git config --local user.name 'GitHub Action'
git config --local user.email 'action@github.com'
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

for arch [amd64 arm64] {
    tmp E:GOOS = 'linux'
    tmp E:GOARCH = $arch
    xcaddy build latest ^
        --with github.com/caddy-dns/cloudflare ^
        --with github.com/mholt/caddy-webdav ^
        --with github.com/lindenlab/caddy-s3-proxy ^
        --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive ^
        --output 'caddy_'$arch
    git add 'caddy_'$arch
}

git commit -am $latest_version
git push -v --progress