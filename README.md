# ProgressHUD
A Progress HUD for Mac


### Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
 
This is a simple drop-in class for displaying a progress HUD view similar to Apple's private UIProgressHUD class.
The ProgressHUD window spans over the entire space given to it by the initWithFrame constructor and catches all
user input on this region, thereby preventing the user operations on components below the view. The HUD itself is
drawn centered as a rounded semi-transparent view which resizes depending on the user specified content.

This view supports six modes of operation (ProgressHUDMode):
 - `indeterminate` shows a UIActivityIndicatorView
 - `determinateCircular` shows a custom round progress indicator
 - `determinateAnnular` shows a custom annular progress indicator
 - `determinateHorizontalBar` shows a custom horizontal progress indicator
 - `customView` shows an arbitrary, user specified view
 - `text` shows only the text labels

All modes can have optional labels assigned:
 - If the `labelText` property is set and non-empty then a label containing the provided content is placed below the indicator view.
 - If also the `detailsLabelText` property is set then another label is placed below the first label.
