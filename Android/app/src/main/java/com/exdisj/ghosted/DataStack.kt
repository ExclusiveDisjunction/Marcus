package com.exdisj.ghosted

import android.app.Application
import android.content.Context
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.Update
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.WhileSubscribed
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.time.debounce
import java.time.Duration
import java.util.Date
import javax.inject.Inject
import javax.inject.Singleton

enum class JobApplicationState {
    APPLIED,
    UNDER_REVIEW,
    IN_INTERVIEW,
    REJECTED,
    ACCEPTED,
    GHOSTED;

    fun color(colorScheme: ColorScheme): Color {
        return when (this) {
            APPLIED -> colorScheme.onSurface
            UNDER_REVIEW, IN_INTERVIEW -> Color.Blue
            REJECTED -> Color.Red
            ACCEPTED -> Color.Green
            GHOSTED -> Color.Gray
        }
    }
    val description: String
        get() {
            return when (this) {
                APPLIED -> "Applied"
                UNDER_REVIEW -> "Under Review"
                IN_INTERVIEW -> "In Interview"
                REJECTED -> "Rejected"
                ACCEPTED -> "Accepted"
                GHOSTED -> "Ghosted"
            }
        }
}

enum class JobKind {
    FULL_TIME,
    PART_TIME,
    SEASONAL,
    CONTRACTOR;

    val description: String
        get() {
            return when (this) {
                FULL_TIME -> "Full Time"
                PART_TIME -> "Part Time"
                SEASONAL -> "Seasonal"
                CONTRACTOR -> "Contractor/Freelance"
            }
        }
}

enum class JobLocation {
    ON_SITE,
    HYBRID,
    REMOTE;

    val description: String
        get() {
            return when (this) {
                ON_SITE -> "On-Site"
                HYBRID -> "Hybrid"
                REMOTE -> "Remote"
            }
        }
}

@Entity(tableName = "job_applications", indices = [ Index("position"), Index("company") ] )
data class JobApplication(
    @PrimaryKey(autoGenerate = true) val uid: Int = 0,
    val position: String,
    val company: String,
    val location: String,
    val appliedOn: Date,
    val lastUpdated: Date?,
    val state: JobApplicationState,
    val jobKind: JobKind,
    val locationKind: JobLocation,
    val notes: String,
    val website: String
) {

}

data class CompactJobApplication(
    @ColumnInfo(name = "position") val position: String,
    @ColumnInfo(name = "state") val state: JobApplicationState
)


@Dao
interface JobApplicationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(vararg apps: JobApplication)

    @Update
    suspend fun updateAll(vararg apps: JobApplication): Int

    @Delete
    suspend fun delete(app: JobApplication): Int

    @Query("SELECT * FROM job_applications")
    fun getAll() : Flow<List<JobApplication>>

    @Query("SELECT position, state FROM job_applications")
    fun getCompactApps(): Flow<List<CompactJobApplication>>
}

class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }
}

@Database(entities = [JobApplication::class], version = 1)
@TypeConverters(Converters::class)
abstract class DataStack : RoomDatabase() {
    abstract fun jobAppsDao(): JobApplicationDao
}

fun create_db(applicationContext: Context): DataStack {
    return Room.databaseBuilder(
        applicationContext,
        DataStack::class.java,
        "Ghosted.db"
    ).build();
}

@HiltViewModel
class DataStackViewModel @Inject constructor(
    private val db: DataStack
) : ViewModel() {

}

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): DataStack {
        return create_db(context)
    }

    @Provides
    fun provideJobDao(db: DataStack): JobApplicationDao {
        return db.jobAppsDao()
    }
}