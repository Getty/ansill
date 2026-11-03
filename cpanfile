requires 'JSON::MaybeXS', '1.004000';
requires 'Module::Runtime', '0.014';
requires 'Moo', '2.000000';
requires 'Types::Standard', '1.000000';

on test => sub {
  requires 'Test::More', '0.98';
};
