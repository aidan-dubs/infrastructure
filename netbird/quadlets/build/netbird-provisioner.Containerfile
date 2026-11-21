FROM docker.io/python:3-slim

WORKDIR /usr/src/app

COPY ./netbird-provisioner.py .

RUN pip install --no-cache-dir requests

CMD [ "python", "./netbird-provisioner.py" ]
