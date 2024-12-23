# Enhanced XV6 Operating System

---

An enhanced version of MIT's XV6 operating system with additional system calls and advanced scheduling algorithms. The Report files have deeper analyses on the scheduling algorithms and CoW implementation.

## Features

- **System Call Counter**: Track system call usage with `getSysCount`
- **Process Alarm System**: CPU time monitoring with `sigalarm` and `sigreturn`
- **Advanced Scheduling**:
  - Lottery Based Scheduling (LBS)
  - Multi-Level Feedback Queue (MLFQ)

## Getting Started

### Prerequisites

- QEMU emulator
- GCC compiler
- Make build system

### Installation

1. Clone the repository
```bash
git clone [your-repository-url]
cd xv6-enhanced
```

2. Build with desired scheduler
```bash
# For default Round Robin
make clean
make qemu

# For Lottery Based Scheduling
make clean
make qemu SCHEDULER=LBS

# For Multi-Level Feedback Queue
make clean
make qemu SCHEDULER=MLFQ
```

## Usage

### System Call Counter
Track specific system calls:
```bash
$ syscount <mask> command [args]
# Example: Track 'open' system calls
$ syscount 32768 grep hello README.md
```

### Process Alarm
```c
// Set alarm for every 10 ticks
sigalarm(10, handler_function);
```

### Lottery Scheduler
```c
// Assign tickets to process
settickets(5);  // Give process 5 tickets
```

## Scheduling Details

### Lottery Based Scheduling
- Probabilistic scheduling based on ticket allocation
- Default: 1 ticket per process
- Earlier arrival time breaks ties
- Child processes inherit parent's tickets

### Multi-Level Feedback Queue
| Queue | Priority | Time Slice |
|-------|----------|------------|
| Q0    | Highest  | 1 tick     |
| Q1    | High     | 4 ticks    |
| Q2    | Medium   | 8 ticks    |
| Q3    | Low      | 16 ticks   |

> **Note**: Priority boost occurs every 48 ticks
> Queue adjustment happens automatically based on CPU usage

## Testing

### Process Monitor
```bash
# Press Ctrl-P in QEMU to view process states
```

### Scheduler Test
```bash
$ schedulertest           # Basic test
$ schedulertest <n>       # Test with n processes
```

## Implementation

Key modified files:
- `kernel/proc.h`: Process structure
- `kernel/proc.c`: Scheduler implementation
- `kernel/syscall.h`: System call definitions
- `kernel/trap.c`: Timer interrupts
- Makefile: Scheduler configuration

## Debugging

### Available Commands
```bash
$ procdump              # View process states
$ schedulertest -v      # Verbose scheduler testing
```

## Contributing

1. Fork the repository
2. Create your feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

## License

This project is based on MIT's XV6 operating system and follows its licensing terms.

## Acknowledgments

- Based on MIT's XV6 operating system
- Enhanced with additional system calls and scheduling algorithms
