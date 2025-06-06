FROM node:20

# Set the locale environment variables early
ENV LANG=es_CL.UTF-8 \
    LANGUAGE=es_CL:es \
    LC_ALL=es_CL.UTF-8

# Install locales and generate es_CL.UTF-8
RUN apt-get update && \
    apt-get install -y locales && \
    sed -i '/es_CL.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
# Set the locale environment variables again after generating locales
WORKDIR /app

COPY package*.json ./
RUN npm install

EXPOSE 3000
CMD ["node", "index.js"]

# Use the following command to build the Docker image
# docker build -t attendance-app:latest .
# Use the following command to run the Docker container
# docker run -p 3000:3000 attendance-app:latest
# Use the following command to run the Docker container in detached mode
# docker run -d -p 3000:3000 attendance-app:latest
# Use the following command to run the Docker container with a specific name
# docker run -d --name attendance-app -p 3000:3000 attendance-app:latest
# Use the following command to stop the Docker container
# docker stop attendance-app
# Use the following command to remove the Docker container
# docker rm attendance-app
# Use the following command to remove the Docker image
# docker rmi attendance-app:latest
# Use the following command to list all Docker images
# docker images
# Use the following command to list all Docker containers
# docker ps -a
# Use the following command to view the logs of the Docker container
# docker logs attendance-app
# Use the following command to execute a command inside the Docker container
# docker exec -it attendance-app /bin/bash