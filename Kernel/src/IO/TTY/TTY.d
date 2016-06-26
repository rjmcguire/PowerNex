module IO.TTY.TTY;

import Data.Screen;
import Data.Color;
import Data.Font;

import HW.BGA.BGA;
import IO.TTY.ContentBuffer;
import IO.TTY.ContentLine;

class TTY {
public:
	this(BGA bga) {
		buffer = new ContentBuffer();
	}

	this(ContentBuffer buffer) {
		this.buffer = buffer;
	}

	void Write(Args...)(Args args) {
		size_t startPos = count;
		Color fg = defaultFG;
		Color bg = defaultBG;
		SlotFlags flags = defaultFlags;
		foreach (arg; args) {
			alias T = Unqual!(typeof(arg));
			static if (is(T : const char[]) || is(T : const wchar[]))
				write(arg, fg, bg, flags);
			else static if (is(T == BinaryInt)) {
				write("0b", fg, bg, flags);
				writeNumber(cast(ulong)arg, 2, fg, bg, flags);
			} else static if (is(T : V*, V)) {
				write("0x", fg, bg, flags);
				writeNumber(cast(ulong)arg, 16, fg, bg, flags);
			} else static if (is(T == enum))
				writeEnum(arg, fg, bg, flags);
			else static if (is(T == bool))
				write((arg) ? "true" : "false", fg, bg, flags);
			else static if (is(T : char) || is(T : wchar))
				write(arg, fg, bg, flags);
			else static if (isNumber!T)
				writeNumber(arg, 10, fg, bg, flags);
			else
				write(arg.toString, fg, bg, flags);
		}
		if (onChanged)
			onChanged(startPos, count);
	}

	void Writeln(Args...)(Args args) {
		Write(args, '\n');
	}

	void Writef(Args...)(string format, Args args) {
		size_t startPos = count;

	}

	abstract void Clear() {
		buffer.Clear();
	}

protected:
	ContentBuffer buffer;
}
__EOF__
TTY GetBootTTY_() {
	import Data.Util : InplaceClass;

	__gshared TTY tty;
	__gshared ContentBuffer buffer;
	__gshared ubyte[__traits(classInstanceSize, TTY)] ttyBuf;
	__gshared ubyte[__traits(classInstanceSize, TTY)] bufferBuf;
	__gshared ContentLine[0x1000] lineBuffer;

	if (!tty) {
		buffer = InplaceClass!ContentBuffer(bufferBuf, lineBuffer);
		tty = InplaceClass!TTY(ttyBuf, buffer);
	}
	return tty;
}
