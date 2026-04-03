package com.exdisj.ghosted

import android.app.Application
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavBackStackEntry
import androidx.navigation.NavController
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.savedstate.serialization.SavedStateConfiguration
import com.exdisj.ghosted.ui.theme.GhostedTheme
import kotlinx.serialization.Serializable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.NavDestination.Companion.hasRoute
import com.exdisj.ghosted.JobApplications.JobApplications
import dagger.hilt.android.AndroidEntryPoint
import dagger.hilt.android.HiltAndroidApp
import jakarta.inject.Inject

@Serializable
sealed class Page(
    val name: String
) {
    @Serializable
    data object JobApps : Page("Jobs")

    @Serializable
    data object Stats : Page("Statistics")

    @Serializable
    data object FollowUps : Page("Follow-Ups")

    @Serializable
    data object Settings : Page("Settings")

    companion object {
        val all: Array<Page>
            get() {
                return arrayOf<Page>(
                    Page.JobApps,
                    Page.Stats,
                    Page.FollowUps,
                    Page.Settings
                )
            }
    }
}

@HiltAndroidApp
class GhostedApp: Application() {

}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            GhostedTheme {

                val viewModel: DataStackViewModel = hiltViewModel()

                ContentView(viewModel)
            }
        }
    }
}

@Composable
fun ContentView(viewModel: DataStackViewModel, modifier: Modifier = Modifier) {
    val controller = rememberNavController();

    val navBackStackEntry by controller.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination;

    Scaffold(
        modifier = modifier,
        bottomBar = {
            NavigationBar {
                Page.all.forEach { page ->
                    NavigationBarItem(
                        selected = currentDestination?.hasRoute(page::class) == true,
                        onClick = { controller.navigate(page) },
                        icon = { Icon(Icons.Default.Work, contentDescription = null) },
                        label = { Text(page.name) }
                    )
                }
            }
        }
    ) { contentPadding ->
        AppNavHost(controller, Page.JobApps, navBackStackEntry, modifier = Modifier.padding(contentPadding))
    }
}

@Composable
fun AppNavHost(
    navController: NavHostController,
    start: Page,
    backStackEntry: NavBackStackEntry?,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController,
        startDestination = start,
        modifier = modifier
    ) {
        composable<Page.JobApps> { JobApplications() }
        composable<Page.Stats> { Statistics() }
        composable<Page.FollowUps> { FollowUps() }
        composable<Page.Settings> { Settings() }
    }
}



@Composable
fun Statistics(modifier: Modifier = Modifier) {

}

@Composable
fun FollowUps(modifier: Modifier = Modifier) {

}

@Composable
fun Settings(modifier: Modifier = Modifier) {

}


@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    GhostedTheme {
        Greeting("Android")
    }
}