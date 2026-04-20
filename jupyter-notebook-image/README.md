# To build the image
docker build . -t brianbianco/jupyterhub:latest

# To push the image
docker login
docker push brianbianco/jupyterhub:latest

