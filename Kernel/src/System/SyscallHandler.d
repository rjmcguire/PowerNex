module System.SyscallHandler;

import CPU.IDT;
import Data.Register;
import System.Syscall;
import Data.Parameters;
import Data.Address;

struct SyscallHandler {
public:
	static void Init() {
		IDT.Register(0x80, &onSyscall);
	}

private:
	static void onSyscall(Registers* regs) {
		import Data.TextBuffer : scr = GetBootTTY;
		import Task.Scheduler : GetScheduler;

		auto process = GetScheduler.CurrentProcess;

		process.syscallRegisters = *regs;
		with (regs)
	outer : switch (RAX) {
			foreach (func; __traits(derivedMembers, System.Syscall)) {
				foreach (attr; __traits(getAttributes, mixin(func))) {
					static if (is(typeof(attr) == SyscallEntry)) {
		case attr.id:
						mixin(generateFunctionCall!func);
						break outer;
					}
				}
			}
		default:
			scr.Writeln("UNKNOWN SYSCALL: ", cast(void*)RAX);
			process.syscallRegisters.RAX = ulong.max;
			break;
		}
		*regs = process.syscallRegisters;
	}

	static string generateFunctionCall(alias func)() {
		if (!__ctfe) // Without this it tries to use _d_arrayappendT
			return "";
		enum ABI = ["RDI", "RSI", "RDX", "RCX", "R8", "R9", "R10", "R11"];

		alias p = Parameters!(mixin(func));
		string o = func ~ "(";

		foreach (idx, val; p) {
			static if (idx)
				o ~= ", ";
			o ~= "cast(" ~ val.stringof ~ ")" ~ ABI[idx];
		}

		o ~= ");";
		return o;
	}
}
