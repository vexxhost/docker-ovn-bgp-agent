# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:9fbb1acf75178dce2934f73fbbe6c5d3e8c2191689251764da04172faa76cbf1 AS build
ARG OVN_BGP_AGENT_VERSION=7.0.0+a8e.1.8
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ovn-bgp-agent[frr_k8s]==${OVN_BGP_AGENT_VERSION}"
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:a3028101248a25358d16549a4fdbf65826a5ebfd04d91a5e2da2f2b48b07ad68
RUN \
    groupadd -g 42424 ovn-bgp-agent && \
    useradd -u 42424 -g 42424 -M -d /var/lib/ovn-bgp-agent -s /usr/sbin/nologin -c "Ovn-bgp-agent User" ovn-bgp-agent && \
    mkdir -p /etc/ovn-bgp-agent /var/log/ovn-bgp-agent /var/lib/ovn-bgp-agent /var/cache/ovn-bgp-agent && \
    chown -Rv ovn-bgp-agent:ovn-bgp-agent /etc/ovn-bgp-agent /var/log/ovn-bgp-agent /var/lib/ovn-bgp-agent /var/cache/ovn-bgp-agent
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    iproute2 openvswitch-switch
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=build --link /var/lib/openstack /var/lib/openstack
