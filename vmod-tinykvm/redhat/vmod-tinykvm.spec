Name:           vmod-tinykvm
Version:        %{versiontag}
Release:        %{releasetag}%{?dist}
Group:          System Environment/Libraries
Summary:        High-performance KVM sandbox VMOD for Varnish
URL:            https://github.com/varnish/libvmod-tinykvm
License:        BSD-2-Clause
Source0:        %{srcurl}
Source1:        https://github.com/varnish/tinykvm/archive/2aef0386066a324009e0fcae446e5b621752aad2.tar.gz
Source2:        https://github.com/nlohmann/json/archive/9f40a7b454befb6e836b493b41df9e64c7a6fd63.tar.gz
Source3:        https://github.com/cameron314/concurrentqueue/archive/6dd38b8a1dbaa7863aa907045f32308a56a6ff5d.tar.gz


BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  make
BuildRequires:  python3
BuildRequires:  pkg-config
BuildRequires:  libcurl-devel
BuildRequires:  libarchive-devel
BuildRequires:  jemalloc-devel
BuildRequires:  varnish-devel = %{version}-%{release}

BuildRequires:  pkgconfig(varnishapi) >= 6

Requires:       varnish = %{version}-%{release}
Requires:       libcurl
Requires:       libarchive
Requires:       jemalloc


%description
Provides vmod_kvm and vmod_tinykvm for running sandboxed compute
workloads inside Varnish via a lightweight KVM hypervisor.


%prep
%setup -q -n libvmod-tinykvm-%{srcversion}
mkdir -p lib/libkvm/ext/tinykvm lib/libkvm/ext/json lib/libkvm/ext/concurrentqueue
tar -xzf %{SOURCE1} --strip-components=1 -C lib/libkvm/ext/tinykvm
tar -xzf %{SOURCE2} --strip-components=1 -C lib/libkvm/ext/json
tar -xzf %{SOURCE3} --strip-components=1 -C lib/libkvm/ext/concurrentqueue


%build
mkdir -p build
cmake -S. -Bbuild \
    -DCMAKE_BUILD_TYPE=Release \
    -DVARNISH_PLUS=OFF \
    -DPython3_EXECUTABLE=$(which python3)
cmake --build build -j%{?_smp_mflags}


%install
mkdir -p %{buildroot}/usr/lib/varnish/vmods
cp build/libvmod_*.so %{buildroot}/usr/lib/varnish/vmods/


%check
# TODO: run varnishtest suite


%files
/usr/lib/varnish/vmods/libvmod_kvm.so
/usr/lib/varnish/vmods/libvmod_tinykvm.so


%changelog
* Mon Dec 01 2025 Varnish Software <opensource@varnish-software.com> - 1.0.0
- Changelog not maintained
