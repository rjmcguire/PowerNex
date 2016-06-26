module IO.TTY.ContentLine;

import Data.PixelRect;
import Data.Font;
import Data.Color;
import Data.BMPImage;

struct ContentLine {
public:
	this(string text, Font font, Color fg, Color bg) {
		isText = true;

		s.t.text = text.dup;
		s.t.font = font;
		s.t.fg = fg;
		s.t.bg = bg;
	}

	this(BMPImage image) {
		isText = false;
		s.i.image = new BMPImage(image);
	}

	~this() {
		if (isText)
			s.t.text.destroy;
		else
			s.i.image.destroy;
	}

	ulong Height(ulong width) {
		if (isText)
			return ((s.t.text.length * s.t.font.Width + s.t.font.Width - 1) / width) * s.t.font.Height;
		else
			return s.i.image.Height;
	}

	void Render(ref PixelRect pixels) {
		if (isText) {
			long x;
			long y;
			foreach (ch; s.t.text) {
				if (x + s.t.font.Width >= pixels.Width) {
					x = 0;
					y += s.t.font.Height;
				}

				ubyte[] charData = s.t.font.GetChar(ch);
				foreach (long idxRow, ubyte row; charData)
					foreach (column; 0 .. 8)
						pixels.Put(x + column, y + idxRow, (row & (1 << (7 - column))) ? s.t.fg : s.t.bg);

				x += s.t.font.Width;
			}
		} else
			for (long y = 0; y < s.i.image.Height; y++) {
				auto row = s.i.image.Data[y * s.i.image.Width .. y * (s.i.image.Width + 1)];
				for (long x = 0; x < s.i.image.Width; x++)
					pixels.Put(x, y, row[x]);
			}
	}

private:
	bool isText;
	union storage {
		struct Text {
			string text;
			Font font;
			Color fg;
			Color bg;
		};
		Text t;
		struct Image {
			BMPImage image;
		};
		Image i;
	}

	storage s;
}
