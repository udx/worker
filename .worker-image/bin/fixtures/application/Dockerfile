## This Dockerfile is to build a version of this repo on top of hardened UDX Worker image
## Generated with udx/worker, using udx best practices:
## - code goes in /app to keep 12-factor app compliance
## - run the code with `udx run python3 /app/your_script.py`

# get hardened UDX image which contains udx cli
FROM udx/worker:ubuntu

# add python
RUN apt-get update && apt-get install -y python3 python3-pip

## add python packages for ML/AI
RUN pip3 install numpy pandas scikit-learn matplotlib seaborn

# add the repo
ADD . /app

# set the working directory
WORKDIR /app

# run the python script