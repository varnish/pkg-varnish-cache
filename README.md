# Package builder for Varnish Cache tools

[![CI](https://github.com/varnish/pkg-varnish-cache/actions/workflows/packages.yml/badge.svg)](https://github.com/varnish/pkg-varnish-cache/actions/workflows/packages.yml)

[Varnish Cache](https://github.com/varnishcache/varnish-cache) is a very extensible caching reverse-proxy, but if you are a beginner, it can be hard to get started or even to discover which vmods are useful. So this repository has two goals:
- providing a curated list of tools that should be interesting to most users
- building those tools as `deb`/`rpm` packages for easy consumptions

## Selected tools and versions

You can check the authoritative liste of packages and the actual version of each in the [./pkg.env file](https://github.com/varnish/all-packager/blob/actions_first_Stab/pkg.env), but here's the high-level view of what is packaged:
- [varnish-modules](https://github.com/varnish/varnish-modules): a collection of small but useful vmods
- [vmod-cfg](https://github.com/carlosabalde/libvmod-cfg/): read local and remote configuration files from VCL
- [vmod-digest](https://github.com/varnish/libvmod-digest/): checksums and cryptographic primitives
- [vmod-fileserver](https://github.com/varnish-rs/vmod-fileserver/): use a filesystem as backend
- [vmod-geoip2](https://github.com/varnishcache-friends/libvmod-geoip2/): load and query `mmdb` databases
- [vmod-jq](https://github.com/varnishcache-friends/libvmod-jq/): parse and manipulate JSON strings
- [vmod-querystring](https://git.sr.ht/~dridi/vmod-querystring/): filter and sanitize querystring parameters
- [vmod-redis](https://github.com/carlosabalde/libvmod-redis/): query `redis`/`valkey` databases from VCL
- [vmod-reqwest](https://github.com/varnish-rs/vmod-reqwest/): dynamic backends and HTTP requests (support HTTPS and HTTP/2, as well as Brotly)
- [vmod-rers](https://github.com/varnish-rs/vmod-rers/): manipulate VCL strings and HTTP bodies through regex
- [vmod-uuid](https://github.com/otto-de/libvmod-uuid/): generate UUIDs

## Packages

This repository doesn't contain the actual source code for the vmods, only the packaging bits. Packaging is handled by the scripts in [build_scripts](./build_scripts) and driven by the [github actions in .github/](.github/workflows/packages.yml).

However, we also build the packages and [publish them](https://varnish.org/docs/install-guide/install-debian-ubuntu/).

## Supported distributions

Packages are currently built for these platforms:
- `debian:bookworm`
- `debian:trixie`
- `ubuntu:noble`
- `ubuntu:questing`
- `rhel:9`
- `rhel:10*`
- `amazonlinux:2023*`

`*`: `vmod-digest` isn't packaged for those distributions as they don't carry `libmhash` which is a required dependency of the vmod.

## Versioning scheme

To keep things neat and tidy, the version of the packages all follow a simple pattern: `X.Y.Z-R`. `X.Y.Z` is the version of the target Varnish version, and `R` is the package revision. All tools will depend on the Varnish package with exactly the same version.

For each realease, we rebuild and publish all packages, this means:
- a new Varnish release means changing `X.Y.Z` to match the new version and resetting `R` to 1
- a new vmod release would mean just increasing `R`. This means all the other packages get a "gratuitous" new package, but it makes it a lot easier to track for everybody.
