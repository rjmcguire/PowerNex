module IO.TTY.ContentBuffer;

import IO.TTY.ContentLine;
import Data.Color;
import Data.Font;
import Data.BMPImage;

class ContentBuffer {
public:
	alias DataChanged = void function(void* userdata);

	this() {
		buffer = new ContentLine[IncreaseSize];
		otherBuffer = false;
	}

	this(ContentLine[] buffer, size_t count = 0) {
		this.buffer = buffer;
		this.count = 0;
		otherBuffer = true;
	}

	~this() {
		if (!otherBuffer)
			buffer.destroy;
	}

	void Add(string str, Font font, Color fg, Color bg) {
		if (buffer.length == count)
			resize();

		buffer[count++] = ContentLine(str, font, fg, bg);

		if (callback)
			callback(userdata);
	}

	void Add(BMPImage image) {
		if (buffer.length == count)
			resize();

		buffer[count++] = ContentLine(image);

		if (callback)
			callback(userdata);
	}

	void Clear() {
		buffer.destroy;
		buffer.length = IncreaseSize;
	}

	@property ref DataChanged DataChangedCallback() {
		return callback;
	}

	@property ref void* UserData() {
		return userdata;
	}

private:
	enum IncreaseSize = 0x1000 / size_t.sizeof;

	bool otherBuffer;
	ContentLine[] buffer;
	ulong count;

	DataChanged callback;
	void* userdata;

	void resize() {
		if (otherBuffer) {
			ContentLine[] newBuffer = new ContentLine[buffer.length + IncreaseSize];
			foreach (idx, line; buffer)
				newBuffer[idx] = line;
			buffer = newBuffer;
			otherBuffer = false;
		} else
			buffer.length += IncreaseSize;
	}

	void add(ContentLine line) {
		if (buffer.length == count)
			resize();

		buffer[count++] = line;

		if (callback)
			callback(userdata);
	}
}
