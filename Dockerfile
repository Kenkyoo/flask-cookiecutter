# ================================== BUILDER ===================================
ARG INSTALL_PYTHON_VERSION=3.11
ARG INSTALL_NODE_VERSION=20

FROM node:${INSTALL_NODE_VERSION}-bullseye-slim AS node
FROM python:${INSTALL_PYTHON_VERSION}-slim-bullseye AS builder

WORKDIR /app

COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /usr/lib/ /usr/lib/
# See https://github.com/moby/moby/issues/37965
RUN true
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY requirements requirements
RUN pip install --no-cache -r requirements/prod.txt

COPY package.json ./
RUN npm install

COPY webpack.config.js autoapp.py ./
COPY cookiecutter cookiecutter
COPY assets assets
COPY .env.example .env
RUN npm run-script build

# ================================= PRODUCTION =================================
FROM python:${INSTALL_PYTHON_VERSION}-slim-bullseye AS builder

# Traemos Node para poder compilar los assets
COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/

WORKDIR /app

# Instalamos las dependencias de Python necesarias para compilar
COPY requirements requirements
RUN pip install --no-cache -r requirements/prod.txt

# Instalamos las dependencias de Node y compilamos
COPY package.json package.json ./
RUN npm install
COPY . .
ENV FLASK_APP=autoapp.py
ENV FLASK_ENV=production
ENV DATABASE_URL=sqlite:////tmp/build.db
ENV SECRET_KEY=not-so-secret-during-build
ENV SEND_FILE_MAX_AGE_DEFAULT=31536000
ENV BCYPT_LOG_ROUNDS=13
ENV DEBUG_TB_ENABLED=False
ENV DEBUG_TB_INTERCEPT_REDIRECTS=False
ENV CACHE_TYPE=simple
ENV SQLALCHEMY_TRACK_MODIFICATIONS=False
RUN npm run build

EXPOSE 5000
ENTRYPOINT ["/bin/bash", "shell_scripts/supervisord_entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "autoapp:app"]


# ================================= DEVELOPMENT ================================
FROM builder AS development
RUN pip install --no-cache -r requirements/dev.txt
EXPOSE 2992
EXPOSE 5000
CMD gunicorn --bind 0.0.0.0:$PORT --access-logfile - autoapp:app
