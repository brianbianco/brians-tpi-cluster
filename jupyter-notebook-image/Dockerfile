FROM jupyter/base-notebook:python-3.11

USER root
RUN apt-get update && apt-get install -y curl jq

USER 1000

RUN pip install --no-cache-dir \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn \
    mlflow \
    boto3

ENV JUPYTER_ENABLE_LAB=yes
