from flask import Flask, request
from flask_restful import Resource, Api
import pandas as pd
from io import StringIO
from tensorflow.keras.models import load_model
import numpy as np
import requests,json

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


columns = ['latitude', 'longitude','user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z',
           'gyroscope_x', 'gyroscope_y', 'gyroscope_z']


app = Flask(__name__)
api = Api(app)

class HelloWorld(Resource):
    def get(self):
        return {'how to use:': 'to call post, post on /potholes endpoint, similarly for to get yes/no for a particular location'}

import requests

class Pothole(Resource):
    # def get(self):
    #     try:
    #         data = request.data.decode('utf-8')
    #         data_io = StringIO(data)
    #         columns_for_get = ['latitude', 'longitude']  
    #         df = pd.read_csv(data_io, names=columns_for_get)
    #         nearest_points_all = []
    #         if df.shape[0] == 1:
    #             return_message = "Points"
    #             for index, row in df.iterrows():
    #                 lat, lon = row['latitude'], row['longitude']

    #                 lat_long_df = pd.read_csv('all_pothole_data.csv')
    #                 lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
    #                 lat_long_df['distance'] = lat_long_df.apply(lambda row: haversine(lat, lon, row['Latitude'], row['Longitude']), axis=1)        
    #                 nearest_points = lat_long_df[(lat_long_df['distance'] <= 5) & (lat_long_df['Prediction'] > 0.1)]

    #                 if not nearest_points.empty:
    #                     nearest_points = nearest_points.sort_values(by='distance')
    #                     nearest_points_list = nearest_points.to_dict('records')

    #                     # Perform reverse geocoding for each nearest point
    #                     # for point in nearest_points_list:
    #                     #     reverse_geocode_result = self.reverse_geocode(point['Latitude'], point['Longitude'])
    #                     #     point['reverse_geocode'] = reverse_geocode_result

    #                     nearest_points_all.extend(nearest_points_list)

    #             if nearest_points_all:
    #                 return {return_message: nearest_points_all}
    #             else:
    #                 print("No points within 5m radius")
    #                 return {'message': 'No points within 5m radius'}
    #         else:
    #             return_message = "Points"
    #             # want to get previous row data as well as current row data, from second row 
    #             for index, row in df.iterrows():
    #                 if index == 0:
    #                     continue
    #                 lat1, lon1 = df.iloc[index-1]['latitude'], df.iloc[index-1]['longitude']
    #                 lat2, lon2 = row['latitude'], row['longitude']
    #                 lat_long_df = pd.read_csv('all_pothole_data.csv')
    #                 lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
    #                 lat_long_df['distance'] = lat_long_df.apply(lambda row: is_point_on_segment((row['Latitude'], row['Longitude']), (lat1, lon1), (lat2, lon2), tolerance=5), axis=1)
    #                 nearest_points = lat_long_df[(lat_long_df['distance'] == True) & (lat_long_df['Prediction'] > 0.1)]
    #                 if not nearest_points.empty:
    #                     nearest_points = nearest_points.sort_values(by='distance')
    #                     nearest_points_list = nearest_points.to_dict('records')

    #                     # Perform reverse geocoding for each nearest point
    #                     # for point in nearest_points_list:
    #                     #     reverse_geocode_result = self.reverse_geocode(point['Latitude'], point['Longitude'])
    #                     #     point['reverse_geocode'] = reverse_geocode_result

    #                     nearest_points_all.extend(nearest_points_list)

    #             if nearest_points_all:
    #                 return {return_message: nearest_points_all}
    #             else:
    #                 print("No points within 5m radius of the line segment provided.")
    #                 return {'message': 'No points within 5m radius of line segment provided'} 
    #     except Exception as e:
    #         return {'error': str(e)}
    
    # def reverse_geocode(self, latitude, longitude):
    #     REST_KEY = "490a70fb32ef272d74dc59c0bf7b731e"  
    #     base_url = "https://apis.mappls.com/advancedmaps/v1"
    #     url = f"{base_url}/{REST_KEY}/rev_geocode"
    #     params = {
    #         "lat": latitude,
    #         "lng": longitude
    #     }
    #     headers = {
    #         "Content-Type": "application/json"
    #     }
    #     response = requests.get(url, params=params, headers=headers)
    #     if response.status_code == 200:
    #         return response.json()  
    #     else:
    #         return None  

    



    def post(self):
        try:
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            df = pd.read_csv(data_io, names=columns)
            print("Input data:", df)  
            
            mean_latitude_longitude = df[['latitude', 'longitude']].mean()
            pair = [mean_latitude_longitude['latitude'], mean_latitude_longitude['longitude']]
            model_path = "models/model.h5"
            model = load_model(model_path)
            features = df[['user_accelerometer_x', 'user_accelerometer_y', 'user_accelerometer_z', 'gyroscope_x', 'gyroscope_y', 'gyroscope_z']]
            if features.shape[0] > 100:
                features_subset = features.iloc[:100]
            else:
                features_subset = features
            input_data = features_subset.to_numpy().reshape((1, 100, 6, 1))
            prediction = model.predict(input_data)
            prediction = prediction[0][0]
            print("Prediction:", prediction)  
            
            pothole_data = pd.read_csv('all_pothole_data.csv')
            print("Pothole data shape:", pothole_data.shape)  
            print("Pothole data head:", pothole_data.head())   

            pothole_data.columns = ['Latitude', 'Longitude', 'Prediction']
            pothole_data['distance'] = pothole_data.apply(lambda row: haversine(float(pair[0]), float(pair[1]), float(row['Latitude']), float(row['Longitude'])), axis=1) 
            nearby_potholes = pothole_data[pothole_data['distance'] <= 5]
            
            if not nearby_potholes.empty:
                # Calculate EMA of existing points
                # Update the 'Prediction' column using EMA calculation
                pothole_data.loc[pothole_data['distance'] <= 5, 'Prediction'] = 0.9 * pothole_data.loc[pothole_data['distance'] <= 5, 'Prediction'] + (1-0.9) * prediction

                # Drop the 'distance' column
                pothole_data.drop(columns=['distance'], inplace=True)

                # Save the modified DataFrame to CSV without the 'distance' column
                pothole_data.to_csv('all_pothole_data.csv', index=False)

            else:
                # Create df_new using lists instead of scalar values
                df_new = pd.DataFrame({'Latitude': [pair[0]], 'Longitude': [pair[1]], 'Prediction': [prediction]})
                df_new.to_csv('all_pothole_data.csv', mode='a', header=False, index=False)
            
            return_message = "Prediction added to the database"
            
            return {'data received': f'{return_message}. Prediction is {prediction}'}
        except Exception as e:
            return {'error': str(e)}



class Pothole2(Resource):
    def post(self):
        try:
            data = request.data.decode('utf-8')
            data_io = StringIO(data)
            columns_for_get = ['latitude', 'longitude']  
            df = pd.read_csv(data_io, names=columns_for_get)
            nearest_points_all = []
            if df.shape[0] == 1:
                return_message = "Points"
                for index, row in df.iterrows():
                    lat, lon = row['latitude'], row['longitude']

                    lat_long_df = pd.read_csv('all_pothole_data.csv')
                    lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
                    lat_long_df['distance'] = lat_long_df.apply(lambda row: haversine(lat, lon, row['Latitude'], row['Longitude']), axis=1)        
                    nearest_points = lat_long_df[(lat_long_df['distance'] <= 5) & (lat_long_df['Prediction'] > 0.1)]

                    if not nearest_points.empty:
                        nearest_points = nearest_points.sort_values(by='distance')
                        nearest_points_list = nearest_points.to_dict('records')

                        # Perform reverse geocoding for each nearest point
                        # for point in nearest_points_list:
                        #     reverse_geocode_result = self.reverse_geocode(point['Latitude'], point['Longitude'])
                        #     point['reverse_geocode'] = reverse_geocode_result

                        nearest_points_all.extend(nearest_points_list)

                if nearest_points_all:
                    return {return_message: nearest_points_all}
                else:
                    print("No points within 5m radius")
                    return {'message': 'No points within 5m radius'}
            else:
                return_message = "Points"
                # want to get previous row data as well as current row data, from second row 
                for index, row in df.iterrows():
                    if index == 0:
                        continue
                    lat1, lon1 = df.iloc[index-1]['latitude'], df.iloc[index-1]['longitude']
                    lat2, lon2 = row['latitude'], row['longitude']
                    lat_long_df = pd.read_csv('all_pothole_data.csv')
                    lat_long_df.columns = ['Latitude', 'Longitude', 'Prediction']  
                    lat_long_df['distance'] = lat_long_df.apply(lambda row: is_point_on_segment((row['Latitude'], row['Longitude']), (lat1, lon1), (lat2, lon2), tolerance=5), axis=1)
                    nearest_points = lat_long_df[(lat_long_df['distance'] == True) & (lat_long_df['Prediction'] > 0.1)]
                    if not nearest_points.empty:
                        nearest_points = nearest_points.sort_values(by='distance')
                        nearest_points_list = nearest_points.to_dict('records')

                        # Perform reverse geocoding for each nearest point
                        # for point in nearest_points_list:
                        #     reverse_geocode_result = self.reverse_geocode(point['Latitude'], point['Longitude'])
                        #     point['reverse_geocode'] = reverse_geocode_result

                        nearest_points_all.extend(nearest_points_list)

                if nearest_points_all:
                    return {return_message: nearest_points_all}
                else:
                    print("No points within 5m radius of the line segment provided.")
                    return {'message': 'No points within 5m radius of line segment provided'} 
        except Exception as e:
            return {'error': str(e)}
    
    def reverse_geocode(self, latitude, longitude):
        REST_KEY = "490a70fb32ef272d74dc59c0bf7b731e"  
        base_url = "https://apis.mappls.com/advancedmaps/v1"
        url = f"{base_url}/{REST_KEY}/rev_geocode"
        params = {
            "lat": latitude,
            "lng": longitude
        }
        headers = {
            "Content-Type": "application/json"
        }
        response = requests.get(url, params=params, headers=headers)
        if response.status_code == 200:
            return response.json()  
        else:
            return None  

api.add_resource(HelloWorld, '/')
api.add_resource(Pothole, '/potholes')
api.add_resource(Pothole2, '/getPotholes')

if __name__ == '__main__':
    app.run(debug=True)