requires 'Moo' => '2.000000';
requires 'Types::Standard' => '1.000000';
requires 'JSON::MaybeXS' => '1.004000';
requires 'Module::Runtime' => '0.014';
requires 'namespace::autoclean' => '0.28';

on test => sub {
  requires 'Test::More' => '0.98';
  requires 'Test::Exception' => '0.43';
};
