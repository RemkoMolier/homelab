FROM python:3.13-alpine@sha256:40241d5dec48a0bc7a070e2244309fb409cd25509c56fef871494a9bbc57d51e

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
