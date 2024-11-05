FROM continuumio/miniconda3

# Create a new environment and install packages
RUN conda create --name myenv python=3.8

# Activate the environment
SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]

# Install additional packages
RUN conda install numpy pandas
