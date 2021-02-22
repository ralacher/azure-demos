FROM ubuntu:20.04
RUN apt update -y && apt install -y python3-pip python3-dev
COPY ./requirements.txt /app/requirements.txt
WORKDIR /app
EXPOSE 80
RUN pip3 install -r requirements.txt
COPY . /app
ENTRYPOINT [ "python3" ]
CMD [ "app.py" ]