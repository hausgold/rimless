FROM hausgold/ruby:2.7
LABEL org.opencontainers.image.authors="containers@hausgold.de"

# Update system gem
RUN gem update --system '3.4.22'

# Add backports repository
RUN echo 'deb http://archive.debian.org/debian buster-backports main' \
  >> /etc/apt/sources.list

# Install nodejs 22
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -

# Install system packages and the ruby bundless
RUN apt-get update -yqqq && \
  apt-get install -y \
    build-essential nodejs locales sudo vim \
    ca-certificates jq curl cmake \
    bash-completion inotify-tools && \
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && /usr/sbin/locale-gen && \
  gem install bundler -v '~> 2.4.22' --no-document --no-prerelease

# Install kcat (formerly known as kafkacat)
RUN curl -sL https://github.com/edenhill/kcat/archive/refs/tags/1.7.0.tar.gz \
  | tar xfvz - -C /tmp && cd /tmp/kcat-* && ./bootstrap.sh && \
  mv kcat /usr/local/bin && cd / && rm -rf /tmp/kcat-*

# Add new app user
RUN mkdir /app && \
  adduser app --home /home/app --shell /bin/bash \
    --disabled-password --gecos ""
ADD config/docker/shell/ /home/app/
RUN chown app:app -R /app /home/app /usr/local/bundle && \
  mkdir -p /home/app/.ssh && \
  sudo -HEu app bash -c 'bundle config set system "true"'

# Set the root password and grant root access to app
RUN echo 'root:root' | chpasswd
RUN echo 'app ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /app
