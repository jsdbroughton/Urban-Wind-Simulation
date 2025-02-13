FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Istanbul

# 1) Basic system tools + Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netbase \
    tzdata \
    wget \
    software-properties-common \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2) Install OpenFOAM 9 (assuming it's available for 24.04 in the official repo)
RUN wget -O - https://dl.openfoam.org/gpg.key | tee /etc/apt/trusted.gpg.d/openfoam.asc && \
    add-apt-repository http://dl.openfoam.org/ubuntu && \
    apt-get update && apt-get install -y --no-install-recommends openfoam9 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3) Create non-root user and project directory
RUN useradd -ms /bin/bash openfoamRunner && \
    mkdir -p /opt/openfoam9 && \
    chown -R openfoamRunner:openfoamRunner /opt/openfoam9

USER openfoamRunner
WORKDIR /home/openfoamRunner

# 4) Source OpenFOAM environment in .bashrc
RUN echo "source /opt/openfoam9/etc/bashrc" >> ~/.bashrc

# 5) Copy requirements and install Python dependencies
COPY --chown=openfoamRunner:openfoamRunner requirements.txt ./
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt

CMD ["/bin/bash"]
