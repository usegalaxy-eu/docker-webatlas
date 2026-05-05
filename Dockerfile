FROM python:3.10-slim-bookworm AS builder

ARG BIOFORMATS2RAW="0.7.0"
ARG WEBATLAS_FORK_TAG="0.5.3-galaxy4"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget unzip cmake g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and stage bioformats2raw
RUN wget -q -O bioformats2raw.zip https://github.com/glencoesoftware/bioformats2raw/releases/download/v${BIOFORMATS2RAW}/bioformats2raw-${BIOFORMATS2RAW}.zip && \
    unzip bioformats2raw.zip -d /opt/ && \
    rm bioformats2raw.zip

# Download and stage webatlas scripts
RUN wget -q -O webatlas.tar.gz https://github.com/dannyspadaro/webatlas-pipeline/archive/refs/tags/${WEBATLAS_FORK_TAG}.tar.gz && \
    tar -xf webatlas.tar.gz && \
    mkdir /opt/webatlas-bin && \
    cp -r webatlas-pipeline-${WEBATLAS_FORK_TAG}/bin/* /opt/webatlas-bin/ && \
    chmod +x /opt/webatlas-bin/* && \
    rm -rf webatlas.tar.gz webatlas-pipeline-${WEBATLAS_FORK_TAG}

COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip "setuptools<81" distlib --no-cache-dir && \
    pip install --no-cache-dir -r /requirements.txt

# Runtime stage
FROM python:3.10-slim-bookworm

ARG BIOFORMATS2RAW="0.7.0"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libblosc1 libvips libtiff-tools openjdk-17-jre-headless procps zip unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy required from builder
COPY --from=builder /opt/bioformats2raw-${BIOFORMATS2RAW} /usr/local/share/bioformats2raw-${BIOFORMATS2RAW}
RUN ln -sf /usr/local/share/bioformats2raw-${BIOFORMATS2RAW}/bin/bioformats2raw /usr/local/bin/bioformats2raw

COPY --from=builder /opt/webatlas-bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

ENTRYPOINT []
