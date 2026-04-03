package com.exdisj.ghosted.JobApplications

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.exdisj.ghosted.CompactJobApplication
import com.exdisj.ghosted.JobApplication
import com.exdisj.ghosted.JobApplicationDao
import com.exdisj.ghosted.JobApplicationState
import com.exdisj.ghosted.ui.theme.GhostedTheme
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.WhileSubscribed
import javax.inject.Inject
import kotlin.collections.emptyList
import kotlinx.coroutines.flow.stateIn

class JobsRepo @Inject constructor(private val dao: JobApplicationDao) {
    val allCompactJobs = dao.getCompactApps()
    val allJobs = dao.getAll()

    suspend fun addApp(vararg app: JobApplication) = dao.insertAll(*app)
}

@HiltViewModel
class ApplicationsViewModel @Inject constructor(
    private val repo: JobsRepo
) : ViewModel() {
    val uiState: StateFlow<List<CompactJobApplication>> = repo.allCompactJobs
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList<CompactJobApplication>()
        )
}

@Composable
fun JobApplications(
    modifier: Modifier = Modifier,
    viewModel: ApplicationsViewModel = hiltViewModel()
) {
    val jobs by viewModel.uiState.collectAsStateWithLifecycle()

    JobApplicationsContent(jobs, modifier)
}

@Composable
fun JobApplicationActions() {
    var showMenu by remember { mutableStateOf(false) }

    Box(contentAlignment = Alignment.BottomEnd) {
        FloatingActionButton(
            onClick = { showMenu = !showMenu }
        ) {
            Icon(Icons.Default.Add, contentDescription = null)
        }
    }

    DropdownMenu(
        expanded = showMenu,
        onDismissRequest = { showMenu = false }
    ) {
        DropdownMenuItem(
            text = { Text("Add Application") },
            onClick = { },
            leadingIcon = { Icon(Icons.Default.Add, contentDescription = null ) }
        )

        DropdownMenuItem(
            text = { Text("Edit Selected") },
            onClick = { },
            leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null ) }
        )

        DropdownMenuItem(
            text = { Text("Inspect Selected") },
            onClick = { },
            leadingIcon = { Icon(Icons.Default.Info, contentDescription = null ) }
        )

        DropdownMenuItem(
            text = { Text("Delete Selected") },
            onClick = { },
            leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null ) }
        )
    }
}

@Composable
fun JobApplicationsContent(
    jobs: List<CompactJobApplication>,
    modifier: Modifier = Modifier
) {
    Scaffold(
        floatingActionButton = {
            JobApplicationActions()
        },
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = modifier.fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 10.dp)
                .padding(bottom = 10.dp)
        ) {
            Text(
                "Job Applications",
                style = MaterialTheme.typography.headlineLarge,
                modifier = Modifier.padding(bottom = 10.dp)
            )

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        MaterialTheme.colorScheme.surfaceContainer,
                        shape = RoundedCornerShape(5.dp)
                    )
                    .padding(8.dp)
            ) {
                items(jobs) { job ->
                    JobRow(job)
                }
            }
        }
    }
}

@Composable
fun JobRow(job: CompactJobApplication) {
    Column(
        modifier = Modifier.padding(bottom = 5.dp)
    ) {
        Text(
            job.position,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )

        Text(
            job.state.description,
            color = job.state.color(MaterialTheme.colorScheme),
            style = MaterialTheme.typography.bodySmall
        )

        HorizontalDivider()
    }
}

@Composable
fun AddJob() {
    Column(modifier = Modifier.padding(10.dp).fillMaxWidth()) {
        Text("New Job Application", style = MaterialTheme.typography.titleLarge)
    }
}

@Preview(showBackground = true, name = "Light Mode")
@Preview(showBackground = true, uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES, name = "Dark Mode")
@Composable
fun JobApplicationsPreview() {
    val mockJobs = listOf(
        CompactJobApplication(position = "Software Engineer", state = JobApplicationState.IN_INTERVIEW),
        CompactJobApplication(position = "iOS Developer", state = JobApplicationState.REJECTED)
    );

    GhostedTheme {
        JobApplicationsContent(mockJobs)
    }
}