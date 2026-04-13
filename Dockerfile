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
RUN npm run build  # <--- Esto generará la carpeta static/build

COPY . .

EXPOSE 5000
ENTRYPOINT ["/bin/bash", "shell_scripts/supervisord_entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "autoapp:app"]


# ================================= DEVELOPMENT ================================
FROM builder AS development
RUN pip install --no-cache -r requirements/dev.txt
EXPOSE 2992
EXPOSE 5000
CMD [ "npm", "start" ]
