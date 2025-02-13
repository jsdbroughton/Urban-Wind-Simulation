# Use Ubuntu 23.04 as the base image (Python 3.11 is default here)
FROM ubuntu:23.04

# Set non-interactive mode to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Istanbul
ENV VM_PROJECT_DIR=/opt/openfoam9

# Install system dependencies (including python3, which is 3.11 by default on 23.04)
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

# Verify Python version (should be Python 3.11.x)
RUN python3 --version

# Install OpenFOAM 9 (assuming the repository has a release for 23.04)
RUN wget -O - https://dl.openfoam.org/gpg.key | tee /etc/apt/trusted.gpg.d/openfoam.asc \
    && add-apt-repository http://dl.openfoam.org/ubuntu \
    && apt-get update && apt-get install -y --no-install-recommends openfoam9 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for running OpenFOAM
RUN useradd -ms /bin/bash openfoamRunner && \
    mkdir -p $VM_PROJECT_DIR && \
    chown -R openfoamRunner:openfoamRunner $VM_PROJECT_DIR

# Switch to the non-root user
USER openfoamRunner

# Set OpenFOAM environment variables for the non-root user
RUN echo "source /opt/openfoam9/etc/bashrc" >> ~/.bashrc

# Set working directory
WORKDIR /home/openfoamRunner

# Copy project files
COPY --chown=openfoamRunner:openfoamRunner . /home/openfoamRunner/

# Upgrade pip and install Python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt

# Default command
CMD ["/bin/bash"]
