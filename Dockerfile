# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:86a4d7aa783b5d765411788ed98f0df8c95a6a1f5d1308bd206b93175748522c AS build
RUN --mount=type=bind,from=ovn-bgp-agent,source=/,target=/src/ovn-bgp-agent,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/ovn-bgp-agent[frr_k8s]
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:6efe63967fa5fc8ff25c601e3230b1e836a14e94d789ef2f944346429175228b
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
