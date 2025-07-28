FROM python:3.9-slim-buster

WORKDIR /app

COPY robot_server.py .
RUN pip install Flask requests

EXPOSE 5000

CMD ["python", "robot_server.py"]