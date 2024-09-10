FROM python:3.12-alpine@sha256:e0e4d3db19333a970e7acfdcb8863efe065be6c3038ef5018694f98162bffec0

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
