from flask import Flask, request, jsonify
from bson.json_util import dumps, loads
import pymongo
import os

app = Flask(__name__)
wsgi_app = app.wsgi_app

client = pymongo.MongoClient('mongodb://{}:27017'.format(os.environ['MONGO_HOST']))
database = client['app']
collection = database['employees']

@app.route('/', methods=['GET'])
def getAll():
    return dumps(collection.find())

@app.route('/<id>', methods=['GET'])
def getOne(id):
    return dumps(collection.find_one({'id': int(id)}))

@app.route('/', methods=['POST'])
def post():
    collection.insert_one(request.get_json())
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)