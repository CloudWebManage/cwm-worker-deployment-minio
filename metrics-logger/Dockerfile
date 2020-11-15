FROM python:3.8
COPY requirements.txt /opt/
RUN pip install -r /opt/requirements.txt
COPY metrics_logger/ /opt/metrics_logger/
COPY setup.py /opt/
RUN pip install -e /opt
ENV PYTHONUNBUFFERED=no
ENTRYPOINT ["metrics_logger", "start_daemon"]
