# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.2@sha256:80935f0be5e4ef2b64d5b6a428c1dddc2768354baaab3889effc1c7310c644a1 AS build
RUN --mount=type=bind,from=ovn-bgp-agent,source=/,target=/src/ovn-bgp-agent,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/ovn-bgp-agent[frr_k8s]
EOF

FROM ghcr.io/vexxhost/python-base:2024.2@sha256:6628282f898a0a9a09e85c17af10f5441afc0031e6b039bf43a91b09609d170b
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
