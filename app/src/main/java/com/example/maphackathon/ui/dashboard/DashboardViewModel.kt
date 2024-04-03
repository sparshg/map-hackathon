package com.example.maphackathon.ui.dashboard

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class DashboardViewModel : ViewModel() {

    private val _text = MutableLiveData<String>().apply {
        value = "This app collects the gyroscope and accelerometer data when navigating" +
                " and passes the last 2 second data to the sever. \n\n The data is used to" +
                " detect potholes and other road conditions using a deep learning AI model and stored in server.\n\n" +
                "The pothole data stored in server is used to display nearby potholes on their route."
    }
    val text: LiveData<String> = _text
}