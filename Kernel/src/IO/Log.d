module IO.Log;

import IO.COM;
import Data.Address;
import Data.String;
import Data.Util;

__gshared Log log;

/*

TODO: FIX THIS!!!

	Combine this with textmode aswell.

*/

enum LogLevel {
	VERBOSE = '&',
	DEBUG = '+',
	INFO = '*',
	WARNING = '#',
	ERROR = '-',
	FATAL = '!'
}

struct Log {
	private struct SymbolDef {
	align(1):
		ulong Start;
		ulong End;
		ulong NameLength;
	}

	private struct SymbolMap {
	align(1):
		char[4] Magic;
		ulong Count;
		SymbolDef Symbols;
	}

	private int indent;
	private bool enabled;
	private SymbolMap* symbols;

	// XXX: Page fault if this is not wrapped like this!
	static ulong Seconds() {
		import HW.CMOS.CMOS : GetCMOS;

		return GetCMOS.TimeStamp();
	}

	void Init() {
		COM1.Init();
		indent = 0;
		enabled = true;
	}

	@property ref bool Enabled() {
		return enabled;
	}

	void SetSymbolMap(VirtAddress address) {
		SymbolMap* map = cast(SymbolMap*)address.Ptr;
		if (map.Magic[0 .. 4] != "DSYM")
			return;
		symbols = map;
	}

	void opCall(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(LogLevel level, Arg args) {
		char[ulong.sizeof * 8] buf;
		if (!enabled)
			return;
		for (int i = 0; i < indent; i++)
			COM1.Write(' ');

		COM1.Write('[', itoa(Seconds(), buf, 10), ']');
		COM1.Write('[', cast(char)level, "] ", file /*, ": ", func*/ , '@');

		COM1.Write(itoa(line, buf, 10));
		COM1.Write("> ");
		mainloop: foreach (arg; args) {
			alias T = Unqual!(typeof(arg));
			static if (is(T : const char[]))
				COM1.Write(arg);
			else static if (is(T == enum)) {
				foreach (i, e; EnumMembers!T)
					if (arg == e) {
						COM1.Write(__traits(allMembers, T)[i]);
						continue mainloop;
					}
				COM1.Write("cast(");
				COM1.Write(T.stringof);
				COM1.Write(")");
				COM1.Write(itoa(cast(ulong)arg, buf, 10));
			} else static if (is(T == BinaryInt)) {
				COM1.Write("0b");
				COM1.Write(itoa(arg.Int, buf, 2));
			} else static if (is(T : V*, V)) {
				COM1.Write("0x");
				COM1.Write(itoa(cast(ulong)arg, buf, 16));
			} else static if (is(T == VirtAddress) || is(T == PhysAddress) || is(T == PhysAddress32)) {
				COM1.Write("0x");
				COM1.Write(itoa(cast(ulong)arg.Int, buf, 16));
			} else static if (is(T == bool))
				COM1.Write((arg) ? "true" : "false");
			else static if (is(T : char))
				COM1.Write(arg);
			else static if (isNumber!T)
				COM1.Write(itoa(arg, buf, 10));
			else static if (isFloating!T)
				COM1.Write(dtoa(cast(double)arg, buf, 10));
			else
				COM1.Write("UNKNOWN TYPE '", T.stringof, "'");
		}

		COM1.Write("\r\n");
	}

	void Verbose(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.VERBOSE, args);
	}

	void Debug(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.DEBUG, args);
	}

	void Info(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.INFO, args);
	}

	void Warning(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.WARNING, args);
	}

	void Error(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.ERROR, args);
	}

	void Fatal(string file = __FILE__, string func = __PRETTY_FUNCTION__, int line = __LINE__, Arg...)(Arg args) {
		this.opCall!(file, func, line)(LogLevel.FATAL, args);
		PrintStackTrace(true);
		import IO.TextMode : GetScreen;

		GetScreen.WriteStatus("\t\tFATAL ERROR, READ COM.LOG!");
		asm {
		forever:
			hlt;
			jmp forever;
		}
	}

	void PrintStackTrace(bool skipFirst = false) {
		COM1.Write("\r\nSTACKTRACE:\r\n");
		VirtAddress rbp;
		VirtAddress rip;
		asm {
			mov rbp, RBP;
		}

		if (skipFirst) {
			rip = rbp + ulong.sizeof;
			rbp = VirtAddress(*rbp.Ptr!ulong);
		}

		while (rbp && //
				rbp > 0xFFFF_FFFF_8000_0000 && rbp < 0xFFFF_FFFF_F000_0000 // XXX: Hax fix
				 && *rip.Ptr!ulong) {
			rip = rbp + ulong.sizeof;
			if (!*rip.Ptr!ulong)
				break;
			COM1.Write("\t[");

			{
				char[ulong.sizeof * 8] buf;
				COM1.Write("0x");
				COM1.Write(itoa(*rip.Ptr!ulong, buf, 16));
			}

			COM1.Write("] ");

			struct func {
				string name;
				ulong diff;
			}

			func getFuncName(ulong addr) {
				if (!symbols)
					return func("Unknown function", 0);

				SymbolDef* symbolDef = &symbols.Symbols;
				for (int i = 0; i < symbols.Count; i++) {
					if (symbolDef.Start <= addr && addr <= symbolDef.End)
						return func(cast(string)(VirtAddress(symbolDef) + SymbolDef.sizeof)
								.Ptr[0 .. symbolDef.NameLength], addr - symbolDef.Start);
					symbolDef = cast(SymbolDef*)(VirtAddress(symbolDef) + SymbolDef.sizeof + symbolDef.NameLength).Ptr;
				}

				return func("Symbol not in map!", 0);
			}

			func f = getFuncName(*rip.Ptr!ulong);

			COM1.Write(f.name);
			if (f.diff) {
				char[ulong.sizeof * 8] buf;
				COM1.Write("+0x");
				COM1.Write(itoa(f.diff, buf, 16));
			}

			COM1.Write("\r\n");
			rbp = VirtAddress(*rbp.Ptr!ulong);
		}
	}

}
