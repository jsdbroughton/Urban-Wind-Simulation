# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set non-interactive mode to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Istanbul
ENV VM_PROJECT_DIR=/opt/openfoam9

# Install required system dependencies and Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netbase \
    tzdata \
    wget \
    software-properties-common \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as the default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11

# Verify Python version
RUN python3 --version

# Install OpenFOAM (if required)
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

# Set OpenFOAM environment variables for non-root user
RUN echo "source /opt/openfoam9/etc/bashrc" >> ~/.bashrc

# Set working directory
WORKDIR /home/openfoamRunner/

# Copy project files
COPY --chown=openfoamRunner:openfoamRunner . /home/openfoamRunner/

# Upgrade pip and install Python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt

# Default command
CMD ["/bin/bash"]
