# Web Layout Fix

Fixed the Web landing page layout exception caused by the Record/Plan/Save/Learn row using `CrossAxisAlignment.stretch` inside a vertically unbounded `SingleChildScrollView`.

The cards now use their explicit fixed height and are vertically centered, preventing the `BoxConstraints forces an infinite height` exception and the cascading `Cannot hit test a render box that has never been laid out` errors.

The latest source also retains the responsive landing gradient, aligned feature cards, and Web login navigation.
