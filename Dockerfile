FROM python:3.10-alpine3.19
LABEL maintainer="Mohadeseh Atyabi"

# Print outputs of the running App on the console
ENV PYTHONUNBUFFERED 1

# Copy requirements.txt file from local to docker image
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
# Default working directory when running commands in docker image (where Django project is sent to)
WORKDIR /app
# Expose port 8000 from container to machine when running the container (connect to Djando developement server)
EXPOSE 8000

# The default mode is not the developement and if we want to switch to the developement mode, we have to assign a true value to this variable, which we do in the docker-compose file (which will be run after running this file)
ARG DEV=false
RUN python -m venv /py && \
    # Installes the latest version of pip in this env
    /py/bin/pip install --upgrade pip && \
    # Add some dependencies in order to install psycopg2 package. This is a client package to enable psycopg2 to connect to postgresql.
    apk add --update --no-cache postgresql-client && \
    # Group these packages and call them tmp-build-deps, so that we can remove them together. These are virtual packages.
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    # Install the requirement file in the env
    /py/bin/pip install -r /tmp/requirements.txt && \
    # It is a shell statement. This will install requirements.dev.txt in the developement mode, which is not necessary while deploying the project on the server
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    # Remove the tmp directory as we do not need it anymore, so that the image will be as lightweight as possible
    rm -rf /tmp && \
    # Remove tmp-build-deps to keep the image as lightweight as possible. There won't be any excess packages while running, that are not needed to run the application.
    apk del .tmp-build-deps && \
    # Add new user (other than the root user) to prevent them having access to all privileges
    adduser \
        # No password is needed for users to use the application
        --disabled-password \
        # No need for home for each user to keep the image light
        --no-create-home \
        # Specify the name of the user
        django-user

# Update path environment (it is automatically added to any command)
ENV PATH="/py/bin:$PATH"

# Switch to the user (should be the last line)
USER django-user