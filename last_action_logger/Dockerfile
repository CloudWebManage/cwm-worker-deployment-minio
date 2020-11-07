FROM python:3.8
COPY requirements.txt /opt/
RUN pip install -r /opt/requirements.txt
COPY server.py /opt/
ENV PYTHONUNBUFFERED=no
ENTRYPOINT ["python", "/opt/server.py"]
