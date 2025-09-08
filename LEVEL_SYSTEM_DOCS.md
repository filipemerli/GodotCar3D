# Level System Documentation

## 🎯 **BaseRaceLevel System**

The new BaseRaceLevel system provides a reusable, scalable solution for creating all 8 race levels with minimal code duplication.

## 📁 **File Structure**

```
scenes/levels/
├── level_template.tscn    # Template for new levels  
├── level_01.tscn         # Desert Loop (converted from test_scene)
├── level_02.tscn         # (to be created)
├── ...
└── level_08.tscn         # (to be created)

scripts/levels/
└── base_race_level.gd    # Base class for all levels
```

## 🚀 **Creating a New Level**

### **Method 1: Duplicate Template**
1. Duplicate `level_template.tscn`
2. Rename to `level_XX.tscn`
3. Set `track_id` in the inspector
4. Position `SpawnPoint` node
5. Add checkpoint instances to `Checkpoints` container
6. Add your track geometry to `TrackGeometry` container
7. Configure lightmap data if needed

### **Method 2: Manual Creation**
```gdscript
# Required scene structure:
Level_XX (Node3D)
├── WorldEnvironment (instance)
├── BakeThisLight (instance)  
├── TrackGeometry (Node3D) - Your track meshes
├── Environment (Node3D) - Trees, decorations
├── SpawnPoint (Node3D) - MANUAL: Car spawn position
├── Checkpoints (Node3D) - MANUAL: Container for checkpoints
├── LightmapGI (LightmapGI) - For baked lighting
└── [Other nodes as needed]
```

## ⚙️ **BaseRaceLevel Configuration**

```gdscript
# Export variables (set in Inspector):
track_id = "track_01"              # Unique track identifier
spawn_point = NodePath("SpawnPoint")           # Reference to spawn point
checkpoints_container = NodePath("Checkpoints") # Reference to checkpoint container
```

## 🔄 **Auto-Created Components**

The BaseRaceLevel automatically creates:
- ✅ Control node with velocity/timer labels
- ✅ MobileControl for touch input
- ✅ EndRaceMenu for race completion
- ✅ CheckpointManager for checkpoint logic
- ✅ TrackTimer for race timing
- ✅ Checkpoint sound player

## 🎮 **LoadingManager Integration**

```gdscript
# Load any level by track ID:
LoadingManager.load_level("track_01")
LoadingManager.load_level("track_02", false) # Without loading screen
```

## ✨ **Benefits**

- **2-minute level creation**: Just set track_id and position key nodes
- **Zero code duplication**: All logic in BaseRaceLevel  
- **Consistent behavior**: Every level works identically
- **Easy maintenance**: Fix bugs once, affects all levels
- **LoadingManager ready**: Levels work seamlessly with async loading

## 🎯 **Next Steps**

1. **Test level_01.tscn**: Verify it works exactly like test_scene
2. **Create levels 2-8**: Duplicate template, customize track_id and geometry  
3. **Update car_selection**: Use `LoadingManager.load_level("track_01")` instead of test_scene
4. **Add level progression**: Connect level completion to next level loading

## 🔧 **Manual Tasks Per Level**

You only need to do these manually:
1. **Position SpawnPoint**: Where cars spawn
2. **Place Checkpoints**: Race progress markers  
3. **Add Track Geometry**: Your track meshes/roads
4. **Set track_id**: Unique identifier
5. **Bake Lighting**: If using LightmapGI

Everything else is handled automatically by BaseRaceLevel!
