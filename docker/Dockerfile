FROM python:3.11-slim

RUN cat /etc/*release*
RUN apt update && apt install -y ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && apt install -y docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /home/tbpl/
RUN apt update && apt install -y zip unzip git && \
    # Install SDKMAN
    /usr/bin/bash -c "curl -s https://get.sdkman.io | bash" && \
    # Install Java 17.0.10-tem
    /usr/bin/bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.10-tem" && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Nextflow
ENV PATH="${PATH}:/root/.sdkman/candidates/java/17.0.10-tem/bin/"
RUN /usr/bin/bash -c "curl -s https://get.nextflow.io | bash && chmod +x nextflow && mv nextflow /usr/bin" 