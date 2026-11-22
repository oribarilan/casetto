## 1. Storage

- [x] 1.1 Add a folder size helper to `CasterrCore` with a core test, and use it for the saved charts and downloads
- [x] 1.2 In Settings, show "Downloaded episodes" with its size, and confirm Clear Cache with a checkmark and "Cleared" for about two seconds; extend `testClearCache` to see "Cleared" and the downloads row

## 2. Faster art on launch

- [x] 2.1 Save shrunk art as small JPEG files in the caches folder, keyed by address and size, read them before the original, and delete them in Clear Cache; measure the Shows tab on the phone before and after
- [x] 2.2 In `ArtworkView`, show a grey shimmer while art downloads (still grey with Reduce Motion) and fade into the art, pop in art loaded from the device with no fade, and keep the letter square for no art or a failure; check the shimmer on the simulator with art downloads slowed down for a recording
- [x] 2.3 Remove the temporary timing code; run all core tests and all UI tests once
