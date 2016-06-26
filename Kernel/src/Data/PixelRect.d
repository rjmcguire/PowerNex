module Data.PixelRect;

import Data.Color;
import Data.Screen;

struct PixelRect {
	void Put(long x, long y, Color pixel) {
		x += startX;
		y += startY;

		if (x < 0 || x > screen.Width || y < 0 || y > screen.Height)
			return;
		screen.PixelData[y * screen.Width + x] = pixel;
	}

	@property long Width() {
		return endX - startX;
	}

	@property long Height() {
		return endY - startY;
	}

	Screen screen;
	long startX;
	long startY;
	long endX;
	long endY;
}
