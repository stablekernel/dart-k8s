FROM google/dart

WORKDIR /app
ADD pubspec.* /app/

RUN groupadd -r aqueduct
RUN useradd -m -r -g aqueduct aqueduct
RUN chown -R aqueduct:aqueduct /app

USER aqueduct
RUN pub get --no-precompile

USER root
ADD . /app
RUN chown -R aqueduct:aqueduct /app

USER aqueduct
RUN pub get --offline --no-precompile

EXPOSE 8082

ENTRYPOINT ["pub", "run", "aqueduct:aqueduct", "serve", "--port", "8082"]
