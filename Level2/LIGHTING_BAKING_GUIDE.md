# 💡 Static Light Baking Guide for Level2

## 🎯 Current Status Analysis

### ✅ Already Configured:
- **LightmapGI node** with quality = 2
- **DirectionalLight3D** with proper bake mode (STATIC)
- **Floor mesh** with UV2 coordinates and lightmap size hint
- **Existing lightmap data** (scene_for_lvl_2.lmbake)

### 🔧 Required Improvements:

## 1. **Lighting Setup Optimization**

### Current DirectionalLight3D Settings:
```gdscript
# Good settings already in place:
light_bake_mode = 1  # STATIC - correct for baking
light_energy = 0.85  # Good for realistic lighting
shadow_enabled = true  # Enables shadow baking
sky_mode = 1  # Contributes to sky lighting
```

### Recommended Additional Lights:
- **Fill lights** to reduce harsh shadows
- **Ambient lighting** for better overall illumination
- **Point/Spot lights** for specific areas

## 2. **Mesh Configuration**

### Floor Mesh (Already Good):
```gdscript
lightmap_size_hint = Vector2i(3202, 2752)  # High resolution
add_uv2 = true  # Required for lightmapping
```

### Missing Elements to Add:
- **Walls/Buildings** with proper UV2 coordinates
- **Track barriers** with lightmap setup
- **Decorative objects** with appropriate baking modes

## 3. **LightmapGI Settings to Optimize**

### Current Settings:
```gdscript
quality = 2  # Medium quality (0=Low, 1=Medium, 2=High, 3=Ultra)
```

### Recommended Optimizations:
- **Increase quality to 3** for final builds
- **Add camera_attributes** for exposure control (already done)
- **Configure bounce settings** for realistic indirect lighting

## 4. **Environment Setup**

### Missing WorldEnvironment Improvements:
- **Sky lighting contribution**
- **Ambient color and energy**
- **Fog settings** for atmosphere

## 5. **Performance Considerations**

### Lightmap Resolution Guidelines:
- **Large surfaces** (floor): 1024-2048px per side
- **Medium surfaces** (walls): 512-1024px per side  
- **Small objects**: 256-512px per side

### Baking Time Expectations:
- **Quality 2**: ~30 seconds - 2 minutes
- **Quality 3**: ~2-10 minutes
- **Ultra quality**: ~10+ minutes

## 📋 Step-by-Step Baking Process

### Phase 1: Prepare Scene
1. Ensure all static meshes have UV2 coordinates
2. Set appropriate lightmap_size_hint for each mesh
3. Configure all lights with proper bake_mode

### Phase 2: Configure LightmapGI
1. Set quality level (2 for testing, 3 for final)
2. Add camera attributes for exposure control
3. Configure bounce lighting settings

### Phase 3: Bake Process
1. Select LightmapGI node
2. Click "Bake Lightmaps" in toolbar
3. Wait for completion
4. Test lighting results

### Phase 4: Optimization
1. Adjust light energy and colors
2. Re-bake if needed
3. Optimize lightmap resolutions
4. Final quality bake

## 🎨 Lighting Design Tips

### Realistic Racing Environment:
- **Primary**: Strong directional sun
- **Secondary**: Soft fill lights
- **Ambient**: Sky/environment contribution
- **Accent**: Point lights for specific areas

### Performance vs Quality:
- **Development**: Quality 1-2, lower resolutions
- **Testing**: Quality 2, medium resolutions  
- **Production**: Quality 3, optimized resolutions
- **Final**: Ultra quality for screenshots/marketing
