Async::Command::Multi
=====================
Executes multiple [Async::Command](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command.md) instances.

Synopsis
========

```raku
use Async::Command::Multi;

my %command;
%command<ngroups_max> = </bin/cat /proc/sys/kernel/ngroups_max>;
%command<uptime>      = </usr/bin/uptime>;
    ...
%command<commandN>    = </bin/commandN --cN>;

my $command-manager = Async::Command::Multi.new(:%command, :2time-out, :4batch);
$command-manager.sow;                   # start promises
    
# do other things...
    
my %result = $command-manager.reap;     # await promises

# examine $*OUT from each successfully Kept promise
for %result.keys -> $key {
    printf("[%s] %s:\n", !%result{$key}.exit-code ?? '+' !! '-', $key);
    .say for %result{$key}.stdout-results;
}
```

Methods
=======

new()
-----

    :%command

_keys_ are arbitrary and respected by [Async::Command](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command.md) to maintain associations.

_values_ are independent commands to execute. Absolute paths are encouraged.

    :$time-out

Optional global timer for each promise, in Real seconds. No individual promise should take longer than this number of Real seconds to complete its thread. '0' indicates no time out.

    :$batch

Promise throttle. Default = 16. Mutable for subsequent re-runs.

    :$attempts
    
Optional retry attempts maximum.

    :$delay
    
Optional delay interval between retry attempts.

sow()
-----

Method `sow()` starts multiple [Async::Command](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command.md) instances (promises).

reap()
------

Method `reap()` awaits all sown promises and returns a hash of [Async::Command::Result](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command/Result.md) objects.

Example
=======

_Given_

```raku
#!/usr/bin/env raku
use Async::Command::Multi;
use Data::Dump::Tree;
my %command;
%command<cmd1> = <ssh localhost uname -n>;
%command<cmd2> = <sh notarealcommand>;
ddt Async::Command::Multi.new(:%command, :1time-out).sow.reap;
```

_Output_

```
├ cmd1 => .Async::Command::Result @1
│ ├ @.command = [4][Str] @2
│ │ ├ 0 = ssh.Str
│ │ ├ 1 = localhost.Str
│ │ ├ 2 = uname.Str
│ │ └ 3 = -n.Str
│ ├ $.attempts = 1   
│ ├ $.exit-code = 0   
│ ├ $.stderr-results = .Str
│ ├ $.stdout-results = 
│ │   AREA51
│ │   .Str
│ ├ $.time-out = 1   
│ ├ $.timed-out = False
│ └ $.unique-id = cmd1.Str
└ cmd2 => .Async::Command::Result @3
  ├ @.command = [2][Str] @4
  │ ├ 0 = sh.Str
  │ └ 1 = notarealcommand.Str
  ├ $.attempts = 1   
  ├ $.exit-code = 127   
  ├ $.stderr-results = 
  │   sh: notarealcommand: No such file or directory
  │   .Str
  ├ $.stdout-results = .Str
  ├ $.time-out = 1   
  ├ $.timed-out = False
  └ $.unique-id = cmd2.Str
```
