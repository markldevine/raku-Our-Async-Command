unit        class Async::Command::Result:api<1>:auth<Mark Devine (mark@markdevine.com)>;

has Str     @.command;
has UInt    $.attempts = 1;
has Int     $.exit-code = 1;
has Str     $.stderr-results is required;
has Str     $.stdout-results is required;
has Real    $.time-out = 0;
has Bool    $.timed-out = False;
has Str     $.unique-id;

method set-number-of-attempts-performed (UInt $number-of-attempts-performed where $_ > 0) { $!attempts = $number-of-attempts-performed; }

=finish
