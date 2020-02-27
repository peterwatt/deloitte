FROM python:alpine

MAINTAINER Peter Watt "pjwatt@gmail.com"

RUN pip install flask

COPY . /app

WORKDIR /app

RUN pip install -r requirements.txt

EXPOSE 5000

ENTRYPOINT [ "python" ]

CMD [ "web_app.py" ]
