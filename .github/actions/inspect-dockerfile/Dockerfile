FROM python:3.12-alpine@sha256:aeff64320ffb81056a2afae9d627875c5ba7d303fb40d6c0a43ee49d8f82641c

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
