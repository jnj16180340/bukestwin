from flask import Flask
from flask_bootstrap import Bootstrap

from rq import Queue
from rq.job import Job
from worker import conn
app = Flask(__name__)
app.config.from_object('config')
Bootstrap(app)
q = Queue(connection=conn)

from app import views