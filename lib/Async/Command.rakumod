unit        class Async::Command:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use         Async::Command::Result;

has Str     @.command is required;
has Str     $.unique-id is rw;
has Real    $.time-out = 0.0;

method run (
    UInt :$attempts     where $_ >= 1   = 1;
    Real :$delay        where $_ >= 0.0 = 0.0,
    Real :$time-out,                            # an override of $!time-out, as a convenience for subsequent full-retries
) {
    my $start-instant = now;
    my Real $t-o = 0.0;
    $t-o = $!time-out with $!time-out;
    $t-o = $time-out with $time-out;
    my $original-time-out = $t-o;
    die 'delay (' ~ $delay ~ ')  >= (' ~ $t-o ~ ') time-out' if $delay && $delay >= $t-o;
    my $retry-attempts = $attempts;
    my Async::Command::Result $res;
    my $number-of-attempts-performed = 0;
    while $retry-attempts-- > 0 {
        $res = self!execute(:time-out($t-o));
        $res.set-number-of-attempts-performed(++$number-of-attempts-performed);
        return($res) if $res.exit-code == 0;
        return($res) unless $retry-attempts;
        if ($original-time-out > 0.0) {
            $t-o = $original-time-out - ((now - $start-instant) + $delay);
            return($res) if $t-o <= 0;
        }
        sleep $delay;
    }
    $res;
};

method !execute (
    Real :$time-out,                            # an override of $!time-out, as required
) {
    my Real $t-o = 0.0;
    $t-o = $!time-out with $!time-out;
    $t-o = $time-out with $time-out;
    my $proc = Proc::Async.new(@!command);
    my $c-stderr = Channel.new;
    my $c-stdout = Channel.new;
    my $e-tap = $proc.stderr.tap(-> $e { $c-stderr.send($e) }, quit => { ; });
    my $o-tap = $proc.stdout.tap(-> $o { $c-stdout.send($o) }, quit => { ; });
    my $promise = $proc.start;
    my $waitfor = $promise;
    {
        $waitfor = Promise.anyof(Promise.in($t-o), $promise) if $t-o;
        $ = await $waitfor;
        CATCH { default { $c-stderr.send(.Str); } }
    }
    $o-tap.close;
    $e-tap.close;
    $c-stdout.close;
    $c-stderr.close;
    my $stderr-results = $c-stderr.list.join;
    my $stdout-results = $c-stdout.list.join;

    my $exit-code = -1;
    $exit-code = $promise.result.exitcode if $promise.status ~~ Kept;

    return Async::Command::Result.new(
        :@!command,
        :exit-code($exit-code),
        :$stderr-results,
        :$stdout-results,
        :time-out($t-o),
        :$!unique-id,
    ) if $promise.status ~~ Broken|Kept;

#   Command timed out ($promise.status ~~ Planned)

    $stderr-results = "[timed out]\n" ~ $stderr-results;
    $proc.kill;
    if $promise.status ~~ Planned {
        sleep .5;
        $proc.kill(15);
    }
    if $promise.status ~~ Planned {
        sleep .5;
        $proc.kill(9);
    }
    {
        $ = await $promise;
        CATCH { default { $stderr-results ~=  .Str } }
    }
    return Async::Command::Result.new(
        :@!command,
        :$stdout-results,
        :$stderr-results,
        :time-out($t-o),
        :timed-out,
        :$!unique-id,
    );
}

=finish
