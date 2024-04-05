package com.example.potholemaps

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.BottomAppBar
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.potholemaps.ui.theme.PotholeMapsTheme
import com.mappls.sdk.maps.MapView
import com.mappls.sdk.maps.Mappls
import com.mappls.sdk.services.account.MapplsAccountManager

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MapplsAccountManager.getInstance().restAPIKey = getString(R.string.restAPIKey)
        MapplsAccountManager.getInstance().mapSDKKey = getString(R.string.mapSDKKey)
        MapplsAccountManager.getInstance().atlasClientId = getString(R.string.atlasClientId)
        MapplsAccountManager.getInstance().atlasClientSecret = getString(R.string.atlasClientSecret)
        Mappls.getInstance(applicationContext)
        setContent {
            PotholeMapsTheme {
                MyScreen()
            }
        }
    }
}

@Composable
fun MyScreen() {
    Scaffold(
        topBar = { TitleBar() },
        bottomBar = { BottomNavBar() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            ChipRow()
            Spacer(modifier = Modifier.height(16.dp))
            RoundedAndroidView()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TitleBar() {
    TopAppBar(
        title = { Text(text = "Pothole Detection") }
    )
}

@Composable
fun ChipRow() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        Chip(text = "Chip 1")
        Chip(text = "Chip 2")
        Chip(text = "Chip 3")
    }
}

@Composable
fun Chip(text: String) {
    Card(
        modifier = Modifier.padding(2.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer,
        ),

        ) {
        Text(
            text = text,
            modifier = Modifier.padding(8.dp),
            fontSize = 14.sp
        )
    }
}

@Composable
fun RoundedAndroidView() {
    AndroidView(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp)
            .clip(RoundedCornerShape(16.dp)),
        factory = { context ->
            // Create your Android View here
            // Example: CustomAndroidView(context)
            MapView(context)
        }
    )

}

@Composable
fun BottomNavBar() {
    BottomAppBar(
        containerColor = MaterialTheme.colorScheme.surface,
    ) {
        Text(
            text = "Bottom Bar",
            modifier = Modifier.padding(16.dp)
        )
    }
}