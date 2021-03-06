requires 'Moose';
requires 'DBIx::Class::Schema';
requires 'DBD::SQLite';
requires 'SQL::Translator';
requires 'Digest::SHA';
requires 'Digest::MD5';
requires 'Class::Method::Modifiers';
requires 'DBIx::Class::InflateColumn::Boolean';
requires 'DBD::Pg';

# Mojo support
requires 'Mojo';
requires "EV";
requires 'IO::Socket::Socks';
requires 'IO::Socket::SSL';
#requires "Mojolicious::Plugin::JSON::XS";
requires "Mojo::IOLoop::ReadWriteFork";

on 'test' => sub {
  requires 'Test::DBIx::Class';
  requires 'IO::Scalar';
  requires 'Test::Differences';
};
