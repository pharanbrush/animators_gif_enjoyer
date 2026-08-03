Animator's GIF Enjoyer Deluxe Changelog
===
### 1.1.0 (2026 May 13)
- Updated underlying framework for better Windows compatibility.
- Frame slider now shows individual frame blocks if they fit in the width.
- Scrubbing the frame slider beyond its width can now loop around. (optional)
- Scrubbing the frame number uses a fixed frame-based increment to provide an alternate scrubbing mode.
- Added frame markers. (Shortcut: M)
- Some context menus were updated.
- Clicking start and end frame buttons now set the current frame to the start and end.
- Custom frame range can be toggled by middle-clicking or accessing the context menu of start and end frame buttons.
    - This can also be triggered by double-clicking on the start or end frame buttons when the current frame is already the start or end.
- Window will now show the currently open file's name on top.
- Allowed incrementing the frame (via scrolling or keyboard) to loop around.
- Added 8x playback speed option.
- Now shows file size at the bottom.
- Removed ablity to get gifs from a URL.
- Removed some unnecessary interface rebuilding which should improve performance.

### 1.0.15 (2026 Jan 10) (release skipped)
- Added support for animated AVIF.
- Changed the titlebar "always on top" button to use a more recognizable pin icon.
- GIF frame format warnings are now hidden when animation is not loaded from a GIF.
- Fixed a problem where it was internally reloading the image and causing a visible hitch whenever a large file was loaded.

### 1.0.14 (2025 Mar 8)
- Allow the image sequence import to parse non-padded number sequences. It will still fall back to alphabetical when it fails to find a number sequence.

### 1.0.13 (2025 Mar 6)
- Allow a folder to be dragged into the window as an image sequence import.

### 1.0.12 (2025 Mar 6)
- Added option to make the frame slider fill the width of the window. (toggle this in the context menu or by middle-clicking the frame slider)
- Added "Open image sequence folder..."
- Image sequence defaults to 25fps but can be set by putting a text file in the image sequence folder named `15 fps.txt`. Change the number as needed.
- Fixed not being able to right-click in the empty area around a loaded gif to access the context menu.

### 1.0.11 (2024 Apr 12)
- Added PNG and APNG (Animated PNG) to formally supported format list.

### 1.0.10 (2024 Feb 28)
- Fixed zero-duration frames playing too fast. Now uses the 100ms browser-like default.

### 1.0.9 (2024 Feb 6)
- Replaced "Open file..." button icon

### 1.0.8 (2023 Dec 19)
- Added option to remember window size. (opt-in) 

### 1.0.7 (2023 Dec 1)
- Added option to allow multiple windows.
- Fixed playback of GIFs with slow frames (above 300ms delay).

### 1.0.6 (2023 Nov 27)
- Added zooming. Snaps to container size, then allows silly zoom. Minimum zoom is the size of a Discord inline emote.
- New button to change playback speed.
- Added "Export PNG Sequence...".
- Allow switching between zero-based and one-based display frames in the current frame number's context menu. This also affects the PNG sequence export filenames.
- Added "Reveal in File Explorer" or "Open original link in browser" to context menu. The menu will show the correct item based on the GIF source.
- Allow scrolling on the primary slider to change frames
- Shortened text format for the frame time info.
- Added webp to explicitly-supported formats (it was already compatible anyway).
- Change "Keep Window on Top" button style to be more prominent when activated.
- Fix some tooltip settings to prevent them from blocking buttons on important mouse paths.
- Indicate when the image isn't animated.
- Show the delay of each frame when the image doesn't have a framerate.


### 1.0.4 (2023 Nov 18)
- Added 3 new brightness themes that's saved between sessions.
- New quick interface brightness switch to quickly check what a gif looks like on different backgrounds.
- New custom titlebar is also affected by the brightness switch.
- New toggle to keep the window on top of other windows.
- Added image dimensions to the bottom info text.
- Shortened info text milliseconds to "ms".
- Added invisible resize handles to make window even easier to resize.
- Adjusted button corner radius size.
- Adjusted icon sizes for store and application package. (last update made the sizes really weird on both Windows 10 and 11)

### 1.0.2 (2023 Nov 16)  
- Adjusted store and package icons.

### 1.0.1 (2023 Nov 15)
- First release to the Microsoft Store