# ---------------------------------------------------------------------------
# Settings shared by every target in this project.
# This block is applied to each build's conf/local.conf in addition to the
# per-machine fragment.
# ---------------------------------------------------------------------------

# A small but useful set of packages added to every image. Adjust to taste.
IMAGE_INSTALL:append = " \
    openssh \
    sudo \
    vim \
    nano \
    htop \
    curl \
    wget \
    git \
    rsync \
    e2fsprogs \
    dosfstools \
    parted \
    util-linux \
    kernel-modules \
"

# Convenience image features: a serial/SSH debug login and a package manager
# on the target. Drop "debug-tweaks" for production (it allows empty root pw).
EXTRA_IMAGE_FEATURES ?= "debug-tweaks ssh-server-openssh package-management tools-debug"

# Use systemd as the init manager across all targets.
INIT_MANAGER = "systemd"

# Build-time license acceptance for firmware/packages that need it. Empty by
# default; add entries such as "synaptics-killswitch" only if a recipe asks.
# LICENSE_FLAGS_ACCEPTED = ""
