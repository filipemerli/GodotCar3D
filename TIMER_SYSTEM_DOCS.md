# Track Timer System Usage Documentation

## Overview
The track timer system provides a robust solution for time-based racing challenges in Godot 4. It consists of two main components:

### 1. TrackConfig Resource (`scripts/track_config.gd`)
- Stores track configuration data (name, time limits, difficulty, etc.)
- Reusable across multiple tracks
- Tracks best times and completion statistics
- Provides time formatting utilities

### 2. TrackTimer Component (`scripts/track_timer.gd`)
- Manages the actual timing during gameplay
- Emits signals for UI updates and game events
- Handles warnings, time expiration, and race completion
- Integrates with TrackConfig for configuration data

## Current Setup - Test Track (30.5 seconds)

### Configuration
- **Track Name**: "Test Track - 30.5s Challenge"
- **Time Limit**: 30.5 seconds
- **Warning Threshold**: 10 seconds (yellow warning at 20s, red at 10s)
- **Auto Start**: Disabled (manual start via checkpoint manager)
- **Debug Mode**: Enabled (console output for testing)

### Integration Points

#### With Checkpoint Manager:
- Timer automatically starts when first checkpoint is reached (via script)
- Timer completes successfully when all checkpoints are reached
- Timer fails if time expires before completion

#### With UI:
- Real-time timer display with color coding:
  - White: Normal time remaining
  - Yellow: ≤20 seconds remaining
  - Red: ≤10 seconds remaining (critical)
- Format: "Time: MM:SS.ms" (e.g., "Time: 00:30.50")

### Signals Emitted:
1. `time_warning_triggered(remaining_time)` - When critical time reached
2. `time_expired()` - When time runs out
3. `race_completed(final_time, passed)` - When race ends (success or failure)

### Usage Example:
```gdscript
# In your scene script:
@onready var track_timer: Node = $TrackTimer

func start_race():
    # Timer is already configured via .tscn file
    track_timer.start_timer()

func _on_all_checkpoints_completed():
    # This will trigger race_completed signal with passed=true
    track_timer.complete_race()
```

## Adding New Tracks

### 1. Create New TrackConfig Resource:
```gdscript
# In resources/track_configs/my_track_config.tres
[gd_resource type="Resource" script_class="TrackConfig" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/track_config.gd" id="1"]

[resource]
script = ExtResource("1")
track_name = "My Custom Track"
track_id = "custom_track_01"
time_limit = 45.0  # 45 seconds
warning_threshold = 15.0
difficulty = 3
```

### 2. Update TrackTimer in Scene:
- Set `track_config` property to your new resource
- Adjust `warning_threshold` if needed
- Configure `auto_start` and `show_debug` as desired

## Advanced Features

### Statistics Tracking:
```gdscript
# TrackConfig automatically tracks:
track_config.best_time      # Best completion time
track_config.attempts       # Total attempts
track_config.completions    # Successful completions
track_config.get_success_rate()  # Success percentage
```

### Dynamic Timer Control:
```gdscript
# Runtime control methods:
track_timer.pause_timer()    # Pause countdown
track_timer.resume_timer()   # Resume countdown
track_timer.reset_timer()    # Reset to 0
track_timer.get_progress_percentage()  # 0.0 to 1.0
```

### Custom Time Formatting:
```gdscript
# Format any time value:
var formatted = track_config.get_formatted_time(125.75)
# Returns: "02:05.75"
```

This system is now fully integrated and ready for use!
