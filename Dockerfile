# Use the official Python 3.11 slim base image
FROM python:3.11-slim-bookworm

# Set non-interactive for apt to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Setup timezone
ENV TZ=Europe/Istanbul
ENV VM_PROJECT_DIR=/opt/openfoam9

# Install system dependencies if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netbase \
    tzdata \
    wget \
    software-properties-common \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install OpenFOAM (Optional - if needed, you can remove this section)
RUN wget -O - https://dl.openfoam.org/gpg.key > /etc/apt/trusted.gpg.d/openfoam.asc
RUN add-apt-repository http://dl.openfoam.org/ubuntu
RUN apt-get update && apt-get install -y --no-install-recommends openfoam9

# Set up OpenFOAM environment (if needed)
RUN echo "source /opt/openfoam9/etc/bashrc" >> /root/.bashrc
RUN echo "source /opt/openfoam9/etc/bashrc" >> /home/openfoamRunner/.bashrc

# Create a non-root user
RUN useradd -ms /bin/bash openfoamRunner

# Change the ownership of the project directory to the non-root user
RUN chown -R openfoamRunner:openfoamRunner $VM_PROJECT_DIR

USER openfoamRunner

# Copy the project files (including requirements.txt)
COPY . /home/openfoamRunner/

# Install Python dependencies using pip
RUN pip install --no-cache-dir -r /home/openfoamRunner/requirements.txt

# Set working directory
WORKDIR /home/openfoamRunner/

# Default command
CMD ["/bin/bash"]
