from flask import Flask, request
from flask_restful import Resource, Api
import pandas as pd
from io import StringIO
from tensorflow.keras.models import load_model
import numpy as np

# Define column names
columns = ['Timestamp', 'latitude', 'longitude','user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z',
           'gyroscope_x', 'gyroscope_y', 'gyroscope_z', 'pothole', 'good_road']

app = Flask(__name__)
api = Api(app)
class HelloWorld(Resource):
    def get(self):
        return {'how to use:': 'to call post, post on /potholes endpoint, similarly for to get yes/no for a particular location'}

class Pothole(Resource):
    def get(self):
        return {'yet to do': 'work in progress'}
    def post(self):
        try:
            # Convert bytes data to string
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            df = pd.read_csv(data_io, names=columns)
            print(df)
            mean_latitude_longitude = df[['latitude', 'longitude']].mean()
            pair = [mean_latitude_longitude['latitude'],mean_latitude_longitude['longitude']]
            model_path = "pothole-prophet/models/pothole_model.h5"
            model = load_model(model_path)
            features = df[['user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z', 'gyroscope_x', 'gyroscope_y', 'gyroscope_z']]
            if features.shape[0] > 100:
                features_subset = features.iloc[:100]
            else:
                features_subset = features
            input_data = features_subset.to_numpy().reshape((1, 100, 6, 1))
            prediction = model.predict(input_data)
            print(prediction)
            new_data = ['mean_latitude', 'mean_longitude', 'predicition']
            df_new = pd.DataFrame([[pair[0], pair[1], prediction[0][0]]], columns=new_data)
            df = pd.DataFrame(columns=df.columns)
            print(df)
            print(df_new)
            return {'data received': f'prediction is, {prediction[0][0]}'}
        except Exception as e:
            return {'error': str(e)}


api.add_resource(HelloWorld, '/')
api.add_resource(Pothole, '/potholes')

if __name__ == '__main__':
    app.run(debug=True)
