FROM python:3.12-alpine@sha256:7130f75b1bb16c7c5d802782131b4024fe3d7a87ce7d936e8948c2d2e0180bc4

# Install requirements into the image
COPY requirements.txt /opt/app/requirements.txt

# Install requirements
WORKDIR /opt/app
RUN pip install -r requirements.txt

# Copy the application source
COPY src/inspect_dockerfile.py /opt/app

# Final workdir
WORKDIR /github/workspace

ENTRYPOINT [ "python", "/opt/app/inspect_dockerfile.py" ]
