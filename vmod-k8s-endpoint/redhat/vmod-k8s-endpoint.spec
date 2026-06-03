Name:    vmod-k8s-endpoint
Version: %{versiontag}
Release: %{releasetag}%{?dist}
Summary: Kubernetes endpoint discovery director VMOD for Varnish

License: MIT
URL:     https://github.com/varnish/vmod-k8s_endpoint
Source:  %{srcurl}


BuildRequires:  openssl-devel
BuildRequires:  jq
BuildRequires:  cargo
BuildRequires:  clang-devel
BuildRequires:  varnish-devel = %{version}-%{release}

Requires:       varnish = %{version}-%{release}

%description
Watches a Kubernetes service's endpoints and exposes them as a
randomly-selected director. Backends are added and removed automatically
as pods come and go.


%prep
%setup -q -n vmod-k8s_endpoint-%{srcversion}
cargo fetch --locked


%build
cargo build --frozen --release -j12


%install
install -Dt %{buildroot}/$(pkg-config varnishapi --variable=vmoddir) target/release/libvmod_k8s_endpoint.so


%check
#cargo test --frozen --release


%files
%doc README.md
%license LICENSE
%{_libdir}/varnish/vmods/libvmod_k8s_endpoint.so


%changelog
* Mon Dec 01 2025 Varnish Software <opensource@varnish-software.com> - 1.0.0
- This changelog is not in use.
