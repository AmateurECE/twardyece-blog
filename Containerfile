FROM docker.io/library/debian:bookworm

# Note: Some packages are not used for building, but they are required by
# Jenkins:
# - procps: Jenkins runs the ps(1) tool to test the container started.
# - git: Jenkins performs a git checkout in the container.
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
        curl \
        graphviz \
        plantuml \
        ruby-dev \
        procps \
        git \
        && apt-get clean

# PlantUML Setup
# The version installed by Debian is too old to recognize some of the keywords
# used in various blogposts.
ARG PLANTUML_VERSION=1.2023.13
ARG PLANTUML_DOWNLOAD=https://github.com/plantuml/plantuml/releases/download
RUN curl -L --output /usr/share/plantuml/plantuml.jar \
        ${PLANTUML_DOWNLOAD}/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar

# Install bundler
RUN gem install bundler

WORKDIR /root

# When running "bundle install", install all gems to a user-owned location
RUN /bin/bash -l -c "bundle config set --local path $HOME/.gems"
