Async::Command
==============
Run an individual command as a thread.

[Async::Command::Multi](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command/Multi.md) for running multiple Async::Command instances in parallel.

[Async::Command::Result](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command/Result.md) to view the output data structure of Async::Command.

Synopsis
--------

1-liner: print the STDOUT of a simple command

```
user@AREA51:~> raku -M Async::Command -e 'Async::Command.new(:command</usr/bin/uname -n>).run.stdout-results.print;'
AREA51
```

In a Raku file: run with time-out, adjust & succeed

```raku
#!/usr/bin/env raku
use Async::Command;
my Async::Command $cmd .= new(:command('/usr/bin/sleep', '.01'), :time-out(.001));
my $result = $cmd.run;
```

Gives a poor result [timed out]:

```
.Async::Command::Result @0
├ @.command = [2][Str] @1
│ ├ 0 = /usr/bin/sleep.Str
│ └ 1 = .01.Str
├ $.attempts = 1   
├ $.exit-code = 1
├ $.stderr-results = 
│   [timed out]
│   .Str
├ $.stdout-results = .Str
├ $.time-out = 0.001 (1/1000).Rat
├ $.timed-out = True
└ $.unique-id = Nil
```

Adjust the timeout...

```raku
$result = $cmd.run(:time-out(.1));       # reuse the same command with a new time out
```

Gives the desired result:

```
.Async::Command::Result @0
├ @.command = [2][Str] @1
│ ├ 0 = /usr/bin/sleep.Str
│ └ 1 = .01.Str
├ $.attempts = 1   
├ $.exit-code = 0   
├ $.stderr-results = .Str
├ $.stdout-results = .Str
├ $.time-out = 0.1 (1/10).Rat
├ $.timed-out = False
└ $.unique-id = Nil
```

In a Raku file: lots of retries until exhausted:

```raku
#!/usr/bin/env raku
use Async::Command;
my Async::Command $cmd .= new(:command('/usr/bin/false',)); # `command` likes lists, hence the extra comma
my $result = $cmd.run(:1time-out, :delay(.1), :9attempts);
```

Results in the disappointing failure (not for lack of trying):

```
.Async::Command::Result @0
├ @.command = [1][Str] @1
│ └ 0 = /usr/bin/false.Str
├ $.attempts = 9   
├ $.exit-code = 1   
├ $.stderr-results = .Str
├ $.stdout-results = .Str
├ $.time-out = 0.008214390999999988.Num
├ $.timed-out = False
└ $.unique-id = Nil
```

Description
===========
Aync::Command will
  - execute & manage the specified command in a promise
  - enforce a time out (optionally)
  - retry on failure (optionally)
  - delay in between retry attempts (optionally)
  - capture all results in an [Async::Command::Result](https://github.com/markldevine/raku-Async-Command/blob/main/doc/Async/Command/Result.md) object

Methods
=======

new()
-----

    :@command
    
Required List or Array of the command and arguments. Absolute paths are encouraged.
    
    :$time-out
    
Optional persistent time-out in Real seconds. '0' indicates no time out.

run()
-----

    :$time-out
    
Optional time-out override in Real seconds. Useful for re-running the command with different time out value.

    :$attempts
    
Optional retry attempts maximum.

    :$delay
    
Optional delay interval between retry attempts.

Examples
========
An example script that runs a curl command

```raku
#!/usr/bin/env raku
use Async::Command;
my @command = [
                'curl',
                '-H', 'Content-Type:application/json',
                '-d', '{"user":"myuserid","password":"mYpAsSwOrD!"}',
                '-X', ' POST',
                '-k',
                '-s',
                'https://10.20.30.40/api/get_token',
              ];
my $json-token = Async::Command.new(:@command, :time-out(2.5), :2attempts, :delay(.1)).run.stdout-results;
```
