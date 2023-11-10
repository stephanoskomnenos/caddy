#!/usr/bin/env nu

let latest_version = (curl "https://api.github.com/repos/caddyserver/caddy/releases/latest" | from json | get tag_name | str replace '^v' '')

let current_version = if ('caddy_amd64' | path exists) {
    ^./caddy_amd64 version | split row ' ' | get 0 | str replace '^v' ''
} else {
    'caddy not found'
}

if $latest_version == $current_version {
    print 'there is nothing to do'
} else {
    git config --local user.name 'GitHub Action'
    git config --local user.email 'action@github.com'
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

    ['amd64' 'arm64'] | each { |target_arch| 
        with-env {GOOS: "linux", GOARCH: $target_arch} {
            (xcaddy build latest
                --with github.com/caddy-dns/cloudflare
                --with github.com/mholt/caddy-webdav
                --with github.com/lindenlab/caddy-s3-proxy
                --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
                --output $'caddy_($target_arch)')
        }
        git add $'caddy_($target_arch)'
    }

    git commit -am $latest_version
    git push -v --progress
}
