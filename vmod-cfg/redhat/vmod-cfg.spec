Name:    vmod-cfg
Version: %{versiontag}
Release: %{releasetag}%{?dist}
Summary: Config VMOD for Varnish

License: BSD-2-Clause
URL:     https://github.com/carlosabalde/libvmod-cfg
Source:  %{srcurl}

BuildRequires:	gcc
BuildRequires:  make
BuildRequires:  varnish-devel = %{version}-%{release}
BuildRequires:  libcurl-devel
BuildRequires:  luajit-devel
BuildRequires:  jemalloc-devel
BuildRequires:  vim-common
BuildRequires:  python3-docutils

# Build from a git checkout
BuildRequires:  automake
BuildRequires:  autoconf
BuildRequires:  libtool
BuildRequires:  autoconf-archive

Requires: 	varnish = %{version}-%{release}
Requires: 	libcurl
Requires: 	luajit


%description
This is a collection of modules ("vmods") extending Varnish VCL used
for describing HTTP request/response policies with additional
capabilities. This collection contains the following vmods:
bodyaccess, header, saintmode, tcp, var, vsthrottle, xkey


%prep
%setup -q -n lib%{name}-%{srcversion}


%build
#sh bootstrap
./autogen.sh
%configure --disable-flush-jemalloc-tcache
%make_build


%install
%make_install
find %{buildroot}/%{_libdir}/ -name '*.la' -exec rm -f {} ';'


%check
%make_build check VERBOSE=1


%files
%{_libdir}/varnish/vmods/*
%{_docdir}/*
%{_mandir}/man3/*.3*


%changelog
* Mon Dec 01 2025 Varnish Software <opensource@varnish-software.com> - 1.0.0
- This changelog is not in use.
