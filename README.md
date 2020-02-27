# Deloitte

Response to Deloitte Technical Exercise.

## To run the container

```
docker run -d -p 5000:5000 peterwatt/flaskdemo

curl http://127.0.0.1:5000
```

## Container design

Since Docker Hub doesn’t have an official Flask repository, I built our own. While you can always use a non-official image, it’s generally recommended to make your own Dockerfile to ensure you know what is in the image. 

I am using the Docker Official image [python:alpine](https://hub.docker.com/_/python).

This image is based on the popular Alpine Linux project, available in the alpine official image. Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general. This base image is safe because it is the official image mantained by the Docker community.

The Python code has been changed to bind to 0.0.0.0 (see [here](https://stackoverflow.com/questions/30323224/deploying-a-minimal-flask-app-in-docker-server-connection-issues)). 
