from flask import Flask, request
from flask_restful import Resource, Api
import pandas as pd
from io import StringIO

# Define column names
columns = ['Timestamp', 'accelerometer_x', 'accelerometer_y', 'accelerometer_z',
           'user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z',
           'gyroscope_x', 'gyroscope_y', 'gyroscope_z', 'pothole', 'good_road']

app = Flask(__name__)
api = Api(app)

class HelloWorld(Resource):
    def get(self):
        return {'hello': 'world'}

class Pothole(Resource):
    def get(self):
        return {'pothole': 'pothole'}
    def post(self):
        try:
            # Convert bytes data to string
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            df = pd.read_csv(data_io, names=columns)
            print(df)
            return {'data': 'received'}
        except Exception as e:
            return {'error': str(e)}

api.add_resource(HelloWorld, '/')
api.add_resource(Pothole, '/potholes')

if __name__ == '__main__':
    app.run(debug=True)
