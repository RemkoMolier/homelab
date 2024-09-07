FROM python:3.12-alpine@sha256:4dae8a34125c839fce52c0b4efa963b1be1ce7e84df8eb1a62136049010916da

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
