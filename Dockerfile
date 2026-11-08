# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.2@sha256:5f71266af26b2e9d7a5bb1635bd7de1085bcc96b170c2ed52808fda92371385f AS build
ARG OVN_BGP_AGENT_VERSION=5.0.0+a8e.2.9
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ovn-bgp-agent[frr_k8s]==${OVN_BGP_AGENT_VERSION}"
EOF

FROM ghcr.io/vexxhost/python-base:2025.2@sha256:b2801c0991cc2466bf345c7df5f3aac9a163ee430e0f5b826af2dd2d5363d5c0
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
