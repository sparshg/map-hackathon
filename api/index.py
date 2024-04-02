from flask import Flask, request
from flask_restful import Resource, Api
import pandas as pd
from io import StringIO
from tensorflow.keras.models import load_model
import numpy as np
from math import radians, sin, cos, sqrt, atan2


def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    """
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    distance = 6371 * c * 1000  # Radius of Earth in meters
    return distance

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
        data_pair = request.data.decode('utf-8').split(',')
        lat = float(data_pair[0])
        lon = float(data_pair[1])
        
        # Read the dataframe
        lat_long_df = pd.read_csv('all_pothole_data.csv')
        lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  # Rename columns to match your expected names
        # Calculate distance from each point in the dataframe
        lat_long_df['distance'] = lat_long_df.apply(lambda row: haversine(lat, lon, row['Latitude'], row['Longitude']), axis=1)
        
        # Filter rows within 5m radius
        nearest_points = lat_long_df[lat_long_df['distance'] <= 5]

        if not nearest_points.empty:
            # Sort the dataframe by distance and get the nearest point
            nearest_point = nearest_points.sort_values(by='distance').iloc[0]

            # You can now return this nearest point or do further processing
            print("Nearest point:", nearest_point['Latitude'], nearest_point['Longitude'])
            return {'nearest_point': {'latitude': nearest_point['Latitude'], 'longitude': nearest_point['Longitude']}}
        else:
            print("No points within 5m radius")
            return {'message': 'No points within 5m radius'}
    
    def post(self):
        try:
            # Convert bytes data to string
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            df = pd.read_csv(data_io, names=columns)
            print(df)
            mean_latitude_longitude = df[['latitude', 'longitude']].mean()
            pair = [mean_latitude_longitude['latitude'],mean_latitude_longitude['longitude']]
            model_path = "/Users/yashmundada/Desktop/mapmyindia-apogee-hackathon/pothole-prophet/models/pothole_model.h5"
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
            df_new.to_csv('all_pothole_data.csv', mode='a', header=False, index=False)
            return {'data received': f'prediction is, {prediction[0][0]}'}
        except Exception as e:
            return {'error': str(e)}


api.add_resource(HelloWorld, '/')
api.add_resource(Pothole, '/potholes')

if __name__ == '__main__':
    app.run(debug=True)
