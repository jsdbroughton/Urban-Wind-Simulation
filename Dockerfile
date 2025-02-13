# Use Ubuntu 23.10 (Mantic Minotaur), which has Python 3.11 by default
FROM ubuntu:23.10

# Set non-interactive mode (avoid tzdata prompts, etc.)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Istanbul

# Update packages & install your desired system tools + Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netbase \
    tzdata \
    wget \
    software-properties-common \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Check Python version (should be 3.11 by default)
RUN python3 --version

# Example: install OpenFOAM if there's a package for 23.10
# (You may need to update this if official repos don't yet support 23.10)
RUN wget -O - https://dl.openfoam.org/gpg.key \
    | tee /etc/apt/trusted.gpg.d/openfoam.asc && \
    add-apt-repository http://dl.openfoam.org/ubuntu && \
    apt-get update && apt-get install -y --no-install-recommends \
      openfoam9 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user (optional example)
RUN useradd -ms /bin/bash openfoamRunner

USER openfoamRunner
WORKDIR /home/openfoamRunner

# Copy code, install deps (optional example)
COPY --chown=openfoamRunner:openfoamRunner . /home/openfoamRunner/
RUN python3 -m pip install --user --upgrade pip && \
    python3 -m pip install --user --no-cache-dir -r requirements.txt

CMD ["/bin/bash"]
