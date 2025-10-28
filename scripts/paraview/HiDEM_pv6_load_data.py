from paraview.simple import *

# Delete ALL existing glyphs to clean up
print("Cleaning up old filters...")
for name, proxy in GetSources().items():
    if 'Glyph' in name[0]:
        Delete(proxy)
        print(f"Deleted {name[0]}")

# Now get the VTU file (the actual data)
sources = GetSources()
HiDEM_data = None
for name, proxy in sources.items():
    if '.vtu' in name[0]:
        HiDEM_data = proxy
        print(f"Found VTU data: {name[0]}")
        break

if HiDEM_data is None:
    print("ERROR: VTU file not found! Please load it first.")
else:
    # Create render view
    renderView1 = GetActiveViewOrCreate('RenderView')
    
    # Create fresh Glyph with 2D Glyph type
    glyph1 = Glyph(Input=HiDEM_data, GlyphType='2D Glyph')
    glyph1.GlyphMode = 'All Points'
    glyph1.GlyphType.GlyphType = 'Vertex'
    
    # Show it
    glyph1Display = Show(glyph1, renderView1)
    glyph1Display.Representation = 'Surface'
    glyph1Display.RenderPointsAsSpheres = 1
    glyph1Display.PointSize = 8.0
    
    # Hide original
    Hide(HiDEM_data, renderView1)
    
    # Render
    renderView1.ResetCamera()
    Render()
    
    print("Success! Your DEM should now be visible as points.")
