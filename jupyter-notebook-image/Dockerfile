FROM jupyter/base-notebook:python-3.11

USER root

RUN apt-get update && apt-get install -y curl jq

USER 1000

ENV PATH="/home/jovyan/.local/bin:${PATH}"
RUN curl -LsSf https://astral.sh/uv/install.sh| sh -s

RUN uv pip install --system \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn

ENV JUPYTER_ENABLE_LAB=yes
