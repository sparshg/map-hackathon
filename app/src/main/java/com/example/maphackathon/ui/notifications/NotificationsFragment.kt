package com.example.maphackathon.ui.notifications

import android.content.Context.SENSOR_SERVICE
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.example.maphackathon.databinding.FragmentNotificationsBinding

class NotificationsFragment : Fragment(), SensorEventListener {

    private var _binding: FragmentNotificationsBinding? = null
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val notificationsViewModel =
            ViewModelProvider(this).get(NotificationsViewModel::class.java)

        _binding = FragmentNotificationsBinding.inflate(inflater, container, false)
        val root: View = binding.root
        sensorManager = requireActivity().getSystemService(SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)


        return root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
        sensorManager.unregisterListener(this)
    }
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        // Register the sensor listeners
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        sensorManager.registerListener(this, gyroscope, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            binding.accelerometerTextView.text = "Accelerometer Reading:\nX: ${event.values[0]}\nY: ${event.values[1]}\nZ: ${event.values[2]}"
        } else if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
            binding.gyroscopeTextView.text = "Gyroscope Reading:\nX: ${event.values[0]}\nY: ${event.values[1]}\nZ: ${event.values[2]}"
        }
    }
    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
    }
}