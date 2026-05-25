FROM verdaccio/verdaccio:6.6.0@sha256:722734053e72f998cca9a6337285ea8236b0a8615cff8f6c8c49698e026e7054

ARG MIN_AGE_DAYS=7

USER root
RUN npm install --prefix /verdaccio/plugins @verdaccio/package-filter@13.0.1
COPY conf/config.yaml /verdaccio/conf/config.yaml
RUN sed -i "s/{{MIN_AGE_DAYS}}/${MIN_AGE_DAYS}/g" /verdaccio/conf/config.yaml
USER verdaccio
