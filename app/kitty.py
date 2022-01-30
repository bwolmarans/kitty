#stolen from github.com/lcwyo/gifcat
#this is what you are going to build into a container using Dockerfile (found elsewhere in this repo) and push to ECR (see instructions)
#note originally this was not on port 80, it was on port 5151, but I could never get that to work using fargate and alb, so capitulated and made this port 80.  The Dockerfile is still on 5151 so clearly that does not matter.
from flask import Flask, render_template
import random

app = Flask(__name__)

# list of Brett's cat images
images = [
    "https://i.imgur.com/laIekzr.png",
    "https://i.imgur.com/xbeMRJO.png",
    "https://i.imgur.com/LZmpYyI.png",
    "https://i.imgur.com/G9IsTP4.png"
]


@app.route('/')
def index():
    url = random.choice(images)
    return render_template('index.html', url=url)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
