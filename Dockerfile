# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:86861494fc374ce1cd40240ff09f0506c8651ea069f61cd9743cb3f5437a8d3c AS build
ARG OVN_BGP_AGENT_VERSION=7.0.0+a8e.1.8
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ovn-bgp-agent[frr_k8s]==${OVN_BGP_AGENT_VERSION}"
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:cbf4f7ab43ea8d62ca588720a61762a4b838235c42ed028c0ef2c76e6ead0314
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
