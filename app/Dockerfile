# our base image
FROM alpine:3.5

# Install python and pip
RUN apk add --update py2-pip

# upgrade pip
RUN pip install --upgrade pip

# install Python modules needed by the Python app
RUN mkdir -p /usr/src/kitty
COPY requirements.txt /usr/src/kitty
RUN pip install --no-cache-dir -r /usr/src/kitty/requirements.txt

# copy files required for the app to run
COPY kitty.py /usr/src/kitty/
RUN mkdir -p /usr/srs/kitty/templates
COPY templates/index.html /usr/src/kitty/templates/

# tell the port number the container should expose
EXPOSE 80

# run the application
CMD ["python", "/usr/src/kitty/kitty.py"]
