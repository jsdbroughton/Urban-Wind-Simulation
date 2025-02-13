FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# setup timezone
ENV TZ=Europe/Istanbul
ENV VM_PROJECT_DIR=/opt/openfoam9

# Create a non-root user 
RUN useradd -ms /bin/bash openfoamRunner

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies and Python 3.11
RUN apt update && apt install -y wget software-properties-common python3-pip
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt update
RUN apt-get install -y python3.11 python3.11-distutils

# Ensure python3 points to python3.11
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
RUN update-alternatives --set python3 /usr/bin/python3.11

# Install OpenFOAM and other necessary packages
RUN wget -O - https://dl.openfoam.org/gpg.key > /etc/apt/trusted.gpg.d/openfoam.asc
RUN add-apt-repository http://dl.openfoam.org/ubuntu
RUN apt-get update
RUN apt-get -y --no-install-recommends install openfoam9

RUN echo "source /opt/openfoam9/etc/bashrc" >> /root/.bashrc
RUN echo "source /opt/openfoam9/etc/bashrc" >> /home/openfoamRunner/.bashrc

# Install Poetry
RUN pip install poetry

# Change the ownership of your project directory to the non-root user
RUN chown -R openfoamRunner:openfoamRunner $VM_PROJECT_DIR

USER openfoamRunner

# Copy the project files into the container
COPY . .

# Export the requirements.txt using poetry and install dependencies
RUN poetry export -f requirements.txt --output /home/openfoamRunner/requirements.txt && pip3 install -r /home/openfoamRunner/requirements.txt

CMD ["/bin/bash"]