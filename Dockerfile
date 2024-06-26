FROM amazonlinux:2023

# Install necessary packages
RUN dnf install -y shadow-utils python3.11 python3.11-pip make nodejs20-npm nodejs postgresql15 postgresql15-server

# Create a PostgreSQL user and database
USER postgres
RUN initdb -D /var/lib/pgsql/data
RUN pg_ctl -D /var/lib/pgsql/data -l /tmp/logfile start

# Switch back to the previous user
USER root

# Continue with the rest of the setup
RUN useradd wagtail
EXPOSE 8000
ENV PYTHONUNBUFFERED=1 PORT=8000
COPY requirements.txt /
RUN python3.11 -m pip install -r /requirements.txt
WORKDIR /app
RUN chown wagtail:wagtail /app
COPY --chown=wagtail:wagtail . .
USER wagtail
RUN cd frontend; npm-20 install; npm-20 run build
RUN python3.11 manage.py collectstatic --noinput --clear

# Run migrations and start the server
CMD set -xe; python3.11 manage.py migrate --noinput; gunicorn backend.wsgi:application
