FROM ruby:3.3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

FROM ruby:3.3.11-slim
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/* && \
    groupadd -r rails && useradd -r -g rails -u 1001 rails && \
    chown -R rails:rails /app
COPY --from=builder /app/vendor/bundle /app/vendor/bundle
COPY --chown=rails:rails . .
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    SECRET_KEY_BASE=placeholder bin/rails assets:precompile && \
    mkdir -p tmp/pids tmp/cache tmp/sockets && \
    chown -R rails:rails tmp
RUN mkdir -p /app/tmp && chown -R rails:rails /app/tmp
EXPOSE 3000
USER rails
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]