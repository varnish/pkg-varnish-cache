Name:    vmod-oidc
Version: %{versiontag}
Release: %{releasetag}%{?dist}
Summary: OpenID Connect authentication VMOD for Varnish

License: BSD-2-Clause
URL:     https://github.com/perbu/vmod_oidc
Source:  %{srcurl}

BuildRequires: 	openssl-devel
BuildRequires: 	cargo
BuildRequires: 	clang-devel
BuildRequires:  varnish-devel = %{version}-%{release}

Requires: 	varnish = %{version}-%{release}

%description
Allows Varnish to act as an OpenID Connect Relying Party, authenticating
users against any OIDC-compliant identity provider before serving cached
content. Sessions are stateless and cookie-based.


%prep
%setup -q -n vmod_oidc-%{srcversion}
cargo fetch --locked


%build

cargo build --frozen --release --features vmod -j12


%install
install -Dt %{buildroot}/$(pkg-config varnishapi --variable=vmoddir) target/release/libvmod_oidc.so


%check
export RUST_BACKTRACE=1
cargo test --frozen --release --features vmod --lib


%files
%doc README.md
%license LICENSE.md
%{_libdir}/varnish/vmods/libvmod_oidc.so


%changelog
* Mon Dec 01 2025 Varnish Software <opensource@varnish-software.com> - 1.0.0
- This changelog is not in use.
