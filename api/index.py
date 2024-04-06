from flask import Flask, request
from flask_restful import Resource, Api
import pandas as pd
from io import StringIO
from tensorflow.keras.models import load_model
import numpy as np
from math import radians, sin, cos, sqrt, atan2


def haversine(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = np.radians([lat1, lon1, lat2, lon2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = np.sin(dlat / 2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon / 2)**2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    distance = 6371 * c * 1000  
    return distance

def is_point_on_segment(point, segment_start, segment_end, tolerance):
    distance_segment = haversine(segment_start[0], segment_start[1], segment_end[0], segment_end[1])
    distance_to_start = haversine(point[0], point[1], segment_start[0], segment_start[1])
    distance_to_end = haversine(point[0], point[1], segment_end[0], segment_end[1])
    
    if abs(distance_segment - (distance_to_start + distance_to_end)) <= tolerance:
        return True
    else:
        return False

# if is_point_on_segment(given_point, segment_start, segment_end):
#     print("The given point lies approximately on the line segment.")
# else:
#     print("The given point does not lie approximately on the line segment.")

columns = ['Timestamp', 'latitude', 'longitude','user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z',
           'gyroscope_x', 'gyroscope_y', 'gyroscope_z']


app = Flask(__name__)
api = Api(app)


class HelloWorld(Resource):
    def get(self):
        return {'how to use:': 'to call post, post on /potholes endpoint, similarly for to get yes/no for a particular location'}

class Pothole(Resource):
    def get(self):
        try:
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            columns_for_get = ['latitude', 'longitude']  
            df = pd.read_csv(data_io, names=columns_for_get)
            nearest_points_all = []
            if df.shape[0] ==1:
                return_message = "Only one point was provided, returning nearest points within 5m radius."
                for index, row in df.iterrows():
                    lat, lon = row['latitude'], row['longitude']

                    lat_long_df = pd.read_csv('all_pothole_data.csv')
                    lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
                    lat_long_df['distance'] = lat_long_df.apply(lambda row: haversine(lat, lon, row['Latitude'], row['Longitude']), axis=1)        
                    nearest_points = lat_long_df[(lat_long_df['distance'] <= 5) & (lat_long_df['Prediction'] > 0.1)]

                    if not nearest_points.empty:
                        nearest_points = nearest_points.sort_values(by='distance')
                        nearest_points_list = nearest_points.to_dict('records')
                        nearest_points_all.extend(nearest_points_list)

                if nearest_points_all:
                    return {return_message+'Nearest points'}
                else:
                    print("No points within 5m radius")
                    return {'message': 'No points within 5m radius'}
            else:
                return_message = "more than one point was provided, returning nearest points within 5m radius of the path provided."
                # want to get previous row data as well as current row data, from second row 
                for index, row in df.iterrows():
                    if index == 0:
                        continue
                    lat1, lon1 = df.iloc[index-1]['latitude'], df.iloc[index-1]['longitude']
                    lat2, lon2 = row['latitude'], row['longitude']
                    lat_long_df = pd.read_csv('all_pothole_data.csv')
                    lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
                    lat_long_df['distance'] = lat_long_df.apply(lambda row: is_point_on_segment((row['Latitude'], row['Longitude']), (lat1, lon1), (lat2, lon2), tolerance=0.001), axis=1)
                    nearest_points = lat_long_df[(lat_long_df['distance'] == True) & (lat_long_df['Prediction'] > 0.1)]
                    if not nearest_points.empty:
                        nearest_points = nearest_points.sort_values(by='distance')
                        nearest_points_list = nearest_points.to_dict('records')
                        nearest_points_all.extend(nearest_points_list)
                if nearest_points_all:
                    return {return_message+'Nearest points in 5m radius of the line segment provided': nearest_points_all}
                else:
                    print("No points within 5m radius of the line segment provided.")
                    return {'message': 'No points within 5m radius of line segment provided'} 
        except Exception as e:
            return {'error': str(e)}

    def post(self):
        try:
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            df = pd.read_csv(data_io, names=columns)
            print(df)
            mean_latitude_longitude = df[['latitude', 'longitude']].mean()
            pair = [mean_latitude_longitude['latitude'],mean_latitude_longitude['longitude']]
            model_path = "models/model.h5"
            model = load_model(model_path)
            features = df[['user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z', 'gyroscope_x', 'gyroscope_y', 'gyroscope_z']]
            if features.shape[0] > 100:
                features_subset = features.iloc[:100]
            else:
                features_subset = features
            input_data = features_subset.to_numpy().reshape((1, 100, 6, 1))
            prediction = model.predict(input_data)
            print(prediction)
            new_data = ['mean_latitude', 'mean_longitude', 'prediction']
            df_new = pd.DataFrame([[pair[0], pair[1], prediction[0][0]]], columns=new_data)
            df = pd.DataFrame(columns=df.columns)
            print(df)
            print(df_new)
            if prediction>0.1:
                df_new.to_csv('all_pothole_data.csv', mode='a', header=False, index=False)
                return_message = "prediction, added to the database"
            else:
                return_message = "Prediciton, not added to database"
            return {'data received': f'{return_message}. Prediction is, {prediction[0][0]}'}
        except Exception as e:
            return {'error': str(e)}



api.add_resource(HelloWorld, '/')
api.add_resource(Pothole, '/potholes')

if __name__ == '__main__':
    app.run(debug=True)
