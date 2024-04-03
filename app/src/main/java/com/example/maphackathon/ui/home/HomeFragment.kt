package com.example.maphackathon.ui.home

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.example.maphackathon.databinding.FragmentHomeBinding
import com.mappls.sdk.maps.MapplsMap
import com.mappls.sdk.maps.OnMapReadyCallback
import com.mappls.sdk.maps.annotations.MarkerOptions
import com.mappls.sdk.maps.annotations.PolylineOptions
import com.mappls.sdk.maps.camera.CameraPosition
import com.mappls.sdk.maps.geometry.LatLng

class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null

    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding!!

    private val points = arrayListOf(
        LatLng(28.359720, 75.583702),
        LatLng(28.360503, 75.589285),
        LatLng(28.363260, 75.588758),
        LatLng(28.363126, 75.587867),
    )
    private val potholes = arrayListOf(
        LatLng(28.359943, 75.584959),
        LatLng(28.360469, 75.589042),
        LatLng(28.361753, 75.589042),
        LatLng(28.363188, 75.588120),
    )

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val homeViewModel =
            ViewModelProvider(this).get(HomeViewModel::class.java)

        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        val root: View = binding.root

        binding.mapView.getMapAsync(
            object : OnMapReadyCallback {
                override fun onMapReady(map: MapplsMap) {
                    val cameraPosition = CameraPosition.Builder()
                        .target(LatLng(28.363799, 75.586900))
                        .zoom(15.0)
                        .tilt(0.0)
                        .build()
                    map.cameraPosition = cameraPosition

                    for (point in potholes) {
                        val markerOptions = MarkerOptions().position(point)
                        markerOptions.title = "Marker"
                        markerOptions.snippet = "This is a Marker"
                        map.addMarker(markerOptions)
                    }
                    map.addPolyline(
                        PolylineOptions()
                        .addAll(points)
                        .color(Color.parseColor("#3bb2d0"))
                        .width(4f))
                }

                override fun onMapError(errorCode: Int, errorMessage: String) {
                    // Handle error
                }
            }
        )

//        val textView: TextView = binding.textsHome
//        homeViewModel.text.observe(viewLifecycleOwner) {
//            textView.text = it
//        }
        return root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}