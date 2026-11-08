# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.1@sha256:89cb34a97b1a9e129ada6dfce1401d2efc3c81de5411416888d33e61847333fc AS build
ARG OVN_BGP_AGENT_VERSION=2.1.0+a8e.2.9
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ovn-bgp-agent[frr_k8s]==${OVN_BGP_AGENT_VERSION}"
EOF

FROM ghcr.io/vexxhost/python-base:2024.1@sha256:15cc5ffad84bccbf2e3f17d327c939f661e6dabcdf227282b0bf2f9a35ddba1c
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
